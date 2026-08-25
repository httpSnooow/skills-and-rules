/**
 * Exemplo: Empty State com CTA
 *
 * Estados: Ideal, Empty
 * Contexto: lista de pedidos que pode estar vazia (usuário novo ou sem resultados no filtro).
 *
 * Padrões aplicados:
 * - Token semântico em vez de hex bruto
 * - role="status" + aria-live para anunciar o empty state a leitores de tela
 * - CTA com min-h-[44px] e focus-visible
 * - Imagem decorativa com aria-hidden
 */

// Estados: Empty, Ideal

function PedidosList({ pedidos, onNovoPedido }) {
  if (pedidos.length === 0) {
    return (
      <section
        className="flex flex-col items-center gap-6 py-16 px-4 text-center"
        role="status"
        aria-live="polite"
        aria-label="Nenhum pedido encontrado"
      >
        <img
          src="/illustrations/empty-orders.svg"
          alt=""
          aria-hidden="true"
          width={160}
          height={160}
        />
        <div className="flex flex-col gap-2">
          <h2 className="text-fg-primary text-xl font-semibold">
            Nenhum pedido ainda
          </h2>
          <p className="text-fg-secondary text-sm max-w-xs">
            Seus pedidos aparecerão aqui assim que você fizer sua primeira compra.
          </p>
        </div>
        <button
          onClick={onNovoPedido}
          className="min-h-[44px] px-6 py-2 bg-brand-primary text-fg-on-brand rounded-lg
                     hover:bg-brand-primary-hover active:scale-[0.98]
                     focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2
                     focus-visible:outline-brand-primary"
        >
          Fazer primeiro pedido
        </button>
      </section>
    );
  }

  return (
    <ul aria-label="Lista de pedidos">
      {pedidos.map((pedido) => (
        <li key={pedido.id}>{pedido.numero}</li>
      ))}
    </ul>
  );
}

export default PedidosList;
