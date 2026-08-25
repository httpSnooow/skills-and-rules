/**
 * Exemplo: Tabs (widget composto acessível)
 *
 * Padrões aplicados (WAI-ARIA APG — Tabs Pattern):
 * - role="tablist", role="tab", role="tabpanel"
 * - aria-selected, aria-controls, aria-labelledby
 * - Roving tabindex: tab ativa = tabindex="0", demais = tabindex="-1"
 * - Arrow Keys navegam entre tabs; Tab move foco para fora do tablist
 * - Home/End saltam para primeira/última tab
 * - Ativação automática ao focar (recomendado pelo APG para tabs simples)
 * - tabpanel recebe tabindex="0" para ser focável por teclado
 *
 * Quando usar roving tabindex (vs. aria-activedescendant):
 * - roving tabindex: foco real move entre os itens; leitores de tela anunciam
 *   automaticamente. Usar em tabs, listbox, tree, toolbar, menu.
 * - aria-activedescendant: foco permanece no container (usar em combobox,
 *   onde o campo de input não pode perder o foco durante a navegação da lista).
 * - Nunca misturar os dois no mesmo widget.
 */

import { useState, useRef, useCallback } from 'react';

const TABS = [
  { id: 'tab-overview', label: 'Visão Geral', panelId: 'panel-overview' },
  { id: 'tab-details',  label: 'Detalhes',   panelId: 'panel-details'  },
  { id: 'tab-history',  label: 'Histórico',  panelId: 'panel-history'  },
];

function TabsWidget({ children }) {
  const [activeIndex, setActiveIndex] = useState(0);
  const tabRefs = useRef([]);

  const activateTab = useCallback((index) => {
    setActiveIndex(index);
    tabRefs.current[index]?.focus();
  }, []);

  const handleKeyDown = useCallback((e, index) => {
    const count = TABS.length;
    const keyActions = {
      ArrowRight: () => activateTab((index + 1) % count),
      ArrowLeft:  () => activateTab((index - 1 + count) % count),
      Home:       () => activateTab(0),
      End:        () => activateTab(count - 1),
    };
    if (keyActions[e.key]) {
      e.preventDefault();
      keyActions[e.key]();
    }
  }, [activateTab]);

  return (
    <div>
      <div
        role="tablist"
        aria-label="Seções do produto"
        className="flex gap-0 border-b border-border-default"
      >
        {TABS.map((tab, i) => (
          <button
            key={tab.id}
            id={tab.id}
            role="tab"
            aria-selected={i === activeIndex}
            aria-controls={tab.panelId}
            tabIndex={i === activeIndex ? 0 : -1}
            ref={(el) => { tabRefs.current[i] = el; }}
            onClick={() => activateTab(i)}
            onKeyDown={(e) => handleKeyDown(e, i)}
            className={`px-4 py-3 text-sm font-medium border-b-2 -mb-px
              focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2
              focus-visible:outline-brand-primary
              ${i === activeIndex
                ? 'border-brand-primary text-fg-primary'
                : 'border-transparent text-fg-secondary hover:text-fg-primary hover:border-border-muted'
              }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {TABS.map((tab, i) => (
        <div
          key={tab.panelId}
          id={tab.panelId}
          role="tabpanel"
          aria-labelledby={tab.id}
          hidden={i !== activeIndex}
          tabIndex={0}
          className="p-4 focus-visible:outline focus-visible:outline-2 focus-visible:outline-brand-primary"
        >
          {Array.isArray(children) ? children[i] : children}
        </div>
      ))}
    </div>
  );
}

export default TabsWidget;
