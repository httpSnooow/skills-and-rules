# Kotlin Performance Patterns — Referência Técnica

Índice:
1. N+1 com JPA/Hibernate e JOOQ
2. Cursor pagination com JOOQ e Exposed
3. Bulk writes com JOOQ e Spring Data
4. HikariCP — connection pool
5. Coroutines paralelas (I/O assíncrono)
6. HTTP timeout e retry com Ktor Client
7. Spring Cache com Redis

---

## 1. N+1 com JPA/Hibernate e JOOQ

### JPA: @EntityGraph para eager loading controlado

O `FetchType.LAZY` do JPA é o padrão correto — mas sem `@EntityGraph`, um loop sobre a coleção dispara N queries.

```kotlin
// NÃO — N+1: cada acesso a order.user dispara SELECT
@Repository
interface OrderRepository : JpaRepository<Order, UUID> {
    fun findByUserId(userId: UUID): List<Order>
}

// Uso que causa N+1:
val orders = orderRepository.findByUserId(userId)
orders.forEach { println(it.user.name) } // N queries aqui
```

```kotlin
// SIM — EntityGraph carrega a associação em JOIN
@Repository
interface OrderRepository : JpaRepository<Order, UUID> {

    @EntityGraph(attributePaths = ["user"])
    fun findByUserId(userId: UUID): List<Order>
}

// Alternativa com JPQL explícito (mais previsível):
@Query("SELECT o FROM Order o JOIN FETCH o.user WHERE o.userId = :userId")
fun findByUserIdWithUser(@Param("userId") userId: UUID): List<Order>
```

### JOOQ: colunas explícitas e batch fetch

```kotlin
// NÃO — SELECT * implícito no ORM
fun getOrders(userId: UUID): List<OrderRecord> =
    dsl.selectFrom(ORDERS).where(ORDERS.USER_ID.eq(userId)).fetch()

// SIM — colunas explícitas, JOIN em uma query
fun getOrdersWithUser(userId: UUID): List<OrderWithUser> =
    dsl.select(
        ORDERS.ID,
        ORDERS.TOTAL,
        ORDERS.STATUS,
        ORDERS.CREATED_AT,
        USERS.ID.`as`("userId"),
        USERS.NAME.`as`("userName"),
        USERS.EMAIL.`as`("userEmail"),
    )
    .from(ORDERS)
    .join(USERS).on(USERS.ID.eq(ORDERS.USER_ID))
    .where(ORDERS.USER_ID.eq(userId))
    .fetchInto(OrderWithUser::class.java)
```

### Kotlin Exposed: eager loading com innerJoin

```kotlin
// NÃO — acessa Orders.user fora da transaction → lazy load por acesso = N+1
fun getOrders(userId: UUID): List<Order> = transaction {
    Order.find { Orders.userId eq userId }.toList()
    // Acessar order.user fora daqui pode disparar query extra
}

// SIM — eager load com innerJoin
fun getOrdersWithUser(userId: UUID): List<ResultRow> = transaction {
    (Orders innerJoin Users)
        .select(Orders.id, Orders.total, Orders.status, Users.name, Users.email)
        .where { Orders.userId eq userId }
        .toList()
}
```

---

## 2. Cursor Pagination com JOOQ

```kotlin
data class CursorPage<T>(
    val data: List<T>,
    val nextCursor: UUID?,
    val hasMore: Boolean,
)

fun listOrders(userId: UUID, cursor: UUID?, limit: Int = 20): CursorPage<OrderDto> {
    val take = limit + 1

    val condition = if (cursor != null) {
        ORDERS.USER_ID.eq(userId).and(ORDERS.ID.gt(cursor))
    } else {
        ORDERS.USER_ID.eq(userId)
    }

    val rows = dsl
        .select(ORDERS.ID, ORDERS.TOTAL, ORDERS.STATUS, ORDERS.CREATED_AT)
        .from(ORDERS)
        .where(condition)
        .orderBy(ORDERS.ID.asc())
        .limit(take)
        .fetchInto(OrderDto::class.java)

    val hasMore = rows.size == take
    val data = if (hasMore) rows.dropLast(1) else rows

    return CursorPage(
        data = data,
        nextCursor = if (hasMore) data.last().id else null,
        hasMore = hasMore,
    )
}
```

---

## 3. Bulk Writes com JOOQ e Spring Data

### JOOQ: bulk INSERT com batchInsert
```kotlin
fun bulkInsertLogs(logs: List<LogDto>) {
    val records = logs.map { log ->
        dsl.newRecord(LOGS).apply {
            userId = log.userId
            event = log.event
            createdAt = log.createdAt
        }
    }
    dsl.batchInsert(records).execute()
}
```

### Spring Data JPA: saveAll com chunking
```kotlin
// Spring Data: saveAll já usa batch internamente SE spring.jpa.properties.hibernate.jdbc.batch_size estiver configurado
// application.properties:
//   spring.jpa.properties.hibernate.jdbc.batch_size=500
//   spring.jpa.properties.hibernate.order_inserts=true

fun bulkCreateOrders(orders: List<Order>): List<Order> =
    orderRepository.saveAll(orders)
```

### Chunking para volumes > 1.000
```kotlin
fun <T> List<T>.chunkedOperation(chunkSize: Int = 500, operation: (List<T>) -> Unit) {
    chunked(chunkSize).forEach { chunk -> operation(chunk) }
}

// Uso
allOrders.chunkedOperation(500) { chunk ->
    dsl.batchInsert(chunk.map { it.toRecord() }).execute()
}
```

---

## 4. HikariCP — Connection Pool

### application.yml (Spring Boot)
```yaml
spring:
  datasource:
    url: ${DATABASE_URL}
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      idle-timeout: 600000       # 10 minutos
      connection-timeout: 30000  # 30 segundos
      max-lifetime: 1800000      # 30 minutos (menor que wait_timeout do banco)
      pool-name: MainPool
      leak-detection-threshold: 60000  # detecta conexões não devolvidas ao pool
```

### Limites de pool recomendados
| Cenário | `maximum-pool-size` |
|---|---|
| Serviço único, banco local | 10–20 |
| Multi-instância (k8s) | `(total_db_connections / n_pods) * 0.8` |
| PostgreSQL: max_connections padrão é 100 | Nunca ultrapassar sem aumentar no banco |

### Pool size ≠ "maior = melhor"
Pool muito grande gera contenção no banco (context switching, lock contention). A fórmula da HikariCP:
```
pool_size = (core_count * 2) + effective_spindle_count
```
Para banco SSD moderno: `8 cores × 2 + 1 = 17` é um ponto de partida razoável.

### Detectando connection leak
```
HikariCP: Connection leak detected for thread main on connection com.zaxxer.hikari.pool.PoolBase$1@...
  Apparent connection leak detected.
```
Significa que `connection.close()` não foi chamado. Em JOOQ/Spring, garantir que toda execução está dentro de um bloco de transação gerenciado ou fechando `DSLContext` corretamente.

---

## 5. Coroutines Paralelas (I/O Assíncrono)

### async + await dentro de coroutineScope
```kotlin
// NÃO — sequencial: total = soma das latências
suspend fun getDashboardData(userId: UUID): DashboardDto {
    val user = userService.getUser(userId)
    val orders = orderService.getOrders(userId)
    val balance = walletService.getBalance(userId)
    return DashboardDto(user, orders, balance)
}

// SIM — paralelo: total = max das latências
suspend fun getDashboardData(userId: UUID): DashboardDto = coroutineScope {
    val userDeferred = async { userService.getUser(userId) }
    val ordersDeferred = async { orderService.getOrders(userId) }
    val balanceDeferred = async { walletService.getBalance(userId) }

    DashboardDto(
        user = userDeferred.await(),
        orders = ordersDeferred.await(),
        balance = balanceDeferred.await(),
    )
}
```

### Concorrência limitada — evitar sobrecarregar serviço downstream
```kotlin
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withPermit

val semaphore = Semaphore(10)

suspend fun processUsersLimited(userIds: List<UUID>): List<Result> =
    userIds.map { id ->
        coroutineScope {
            async {
                semaphore.withPermit { processUser(id) }
            }
        }
    }.awaitAll()
```

### awaitAll para lista de deferred
```kotlin
suspend fun fetchAllProfiles(userIds: List<UUID>): List<UserProfile> = coroutineScope {
    userIds.map { id -> async { userService.getProfile(id) } }.awaitAll()
}
```

---

## 6. HTTP Timeout e Retry com Ktor Client

### Ktor Client com timeout configurado
```kotlin
import io.ktor.client.*
import io.ktor.client.engine.cio.*
import io.ktor.client.plugins.*

val httpClient = HttpClient(CIO) {
    install(HttpTimeout) {
        requestTimeoutMillis = 10_000   // timeout total da requisição
        connectTimeoutMillis = 3_000    // timeout de conexão TCP
        socketTimeoutMillis = 5_000     // timeout de leitura de dados
    }
}
```

### Retry com exponential backoff e jitter
```kotlin
import kotlin.math.min
import kotlin.math.pow
import kotlin.random.Random

suspend fun <T> withRetry(
    maxAttempts: Int = 3,
    baseDelayMs: Long = 100,
    maxDelayMs: Long = 5_000,
    block: suspend () -> T,
): T {
    repeat(maxAttempts - 1) { attempt ->
        try {
            return block()
        } catch (e: Exception) {
            if (!e.isRetryable()) throw e
            val exponential = baseDelayMs * 2.0.pow(attempt).toLong()
            val jitter = Random.nextLong(0, exponential)
            val delay = min(exponential + jitter, maxDelayMs)
            delay(delay)
        }
    }
    return block()
}

private fun Exception.isRetryable(): Boolean = when (this) {
    is HttpRequestTimeoutException -> true
    is ConnectTimeoutException -> true
    is ServerResponseException -> this.response.status.value >= 500
    else -> false
}
```

### Ktor com retry plugin
```kotlin
val httpClient = HttpClient(CIO) {
    install(HttpTimeout) { requestTimeoutMillis = 10_000 }
    install(HttpRequestRetry) {
        retryOnServerErrors(maxRetries = 3)
        exponentialDelay(base = 2.0, maxDelayMs = 5_000L)
    }
}
```

---

## 7. Spring Cache com Redis

### Configuração
```kotlin
@Configuration
@EnableCaching
class CacheConfig {

    @Bean
    fun cacheManager(redisConnectionFactory: RedisConnectionFactory): CacheManager {
        val config = RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofMinutes(5))
            .disableCachingNullValues()
            .serializeValuesWith(
                RedisSerializationContext.SerializationPair.fromSerializer(
                    GenericJackson2JsonRedisSerializer()
                )
            )

        return RedisCacheManager.builder(redisConnectionFactory)
            .cacheDefaults(config)
            .withCacheConfiguration(
                "users",
                config.entryTtl(Duration.ofMinutes(5)),
            )
            .withCacheConfiguration(
                "prices",
                config.entryTtl(Duration.ofSeconds(60)),
            )
            .build()
    }
}
```

### Anotações de cache com invalidação explícita
```kotlin
@Service
class UserService(private val userRepository: UserRepository) {

    @Cacheable(cacheNames = ["users"], key = "#id")
    fun getUser(id: UUID): User =
        userRepository.findByIdOrThrow(id)

    @CacheEvict(cacheNames = ["users"], key = "#id")
    fun updateUser(id: UUID, dto: UpdateUserDto): User {
        val user = userRepository.findByIdOrThrow(id)
        return userRepository.save(user.apply { name = dto.name })
    }

    @CacheEvict(cacheNames = ["users"], allEntries = true)
    fun clearUserCache() = Unit
}
```

### TTL por tipo de dado
Ver `references/caching-strategies.md` para a tabela completa e padrão de escolha de TTL.
