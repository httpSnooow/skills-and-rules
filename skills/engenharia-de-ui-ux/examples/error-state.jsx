/**
 * Exemplo: Error State com Retry
 *
 * Estados: Loading, Error, Ideal, Partial
 * Contexto: lista paginada de produtos — a página 1 carrega; a página 2 falha (Partial State).
 *
 * Padrões aplicados:
 * - Skeleton com width + height explícitos (evita Layout Shift)
 * - aria-live="assertive" para erros (anuncia imediatamente a leitores de tela)
 * - Botão Retry com aria-busy durante o retry
 * - Partial State: dados já carregados são mantidos; erro localizado na porção que falhou
 * - Token semântico --color-error-* em vez de red hardcoded
 */

// Estados: Loading, Error, Ideal, Partial

import { useState, useCallback } from 'react';

function ProductList({ fetchProducts }) {
  const [products, setProducts] = useState([]);
  const [page2Error, setPage2Error] = useState(null);
  const [isLoadingPage1, setIsLoadingPage1] = useState(true);
  const [isRetrying, setIsRetrying] = useState(false);

  const retryPage2 = useCallback(async () => {
    setIsRetrying(true);
    setPage2Error(null);
    try {
      const page2 = await fetchProducts({ page: 2 });
      setProducts((prev) => [...prev, ...page2]);
    } catch (err) {
      setPage2Error(err.message);
    } finally {
      setIsRetrying(false);
    }
  }, [fetchProducts]);

  if (isLoadingPage1) {
    return (
      <ul aria-label="Carregando produtos" aria-busy="true">
        {Array.from({ length: 6 }).map((_, i) => (
          <li key={i} className="flex gap-4 p-4">
            <div
              className="bg-surface-skeleton rounded animate-pulse"
              style={{ width: 80, height: 80 }}
              aria-hidden="true"
            />
            <div className="flex flex-col gap-2 flex-1">
              <div
                className="bg-surface-skeleton rounded animate-pulse"
                style={{ width: '60%', height: 20 }}
                aria-hidden="true"
              />
              <div
                className="bg-surface-skeleton rounded animate-pulse"
                style={{ width: '40%', height: 16 }}
                aria-hidden="true"
              />
            </div>
          </li>
        ))}
      </ul>
    );
  }

  return (
    <div>
      <ul aria-label="Lista de produtos">
        {products.map((product) => (
          <li key={product.id}>{product.name}</li>
        ))}
      </ul>

      {page2Error && (
        <div
          role="alert"
          aria-live="assertive"
          className="flex flex-col items-center gap-3 p-6 border border-error-border rounded-lg
                     bg-error-bg text-error-fg mt-4"
        >
          <p className="text-sm">
            Não foi possível carregar mais produtos. {page2Error}
          </p>
          <button
            onClick={retryPage2}
            disabled={isRetrying}
            aria-busy={isRetrying}
            className="min-h-[44px] px-4 py-2 bg-error-action text-fg-on-error rounded-lg
                       hover:bg-error-action-hover
                       disabled:opacity-50 disabled:pointer-events-none
                       focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
          >
            {isRetrying ? 'Tentando novamente...' : 'Tentar novamente'}
          </button>
        </div>
      )}
    </div>
  );
}

export default ProductList;
