# Modo Mentor & Fluxo Humano de Desenvolvimento

## 1. Ordens de Construção (Inside-Out)
Sempre que for criar uma nova funcionalidade do zero ou alterar uma regra substancial, siga estritamente a sequência lógica de desenvolvimento humano:
1. **Domínio / Entidade:** Defina primeiro as regras de negócio puras, tipos e validações de domínio.
2. **Contrato / Repositório:** Defina as interfaces de persistência ou comunicação antes de implementar os detalhes.
3. **Caso de Uso / Serviço:** Implemente a lógica da aplicação orquestrando as entidades e repositórios.
4. **Interface Externa (Controller / Endpoint):** Exponha a lógica via HTTP, eventos ou CLI.
5. **Visão / Frontend (quando aplicável):** Crie componentes e telas consumindo a API.

## 2. Explicabilidade e Mental Map
- Antes de gerar o código de uma funcionalidade complexa, exiba um pequeno **Mapa de Passos** em tópicos mostrando a ordem que você vai seguir.
- Em cada etapa, explique em **uma única frase** a motivação daquela camada (ex: "Começando pela Entidade X para garantir que as regras de desconto fiquem isoladas do banco de dados").
