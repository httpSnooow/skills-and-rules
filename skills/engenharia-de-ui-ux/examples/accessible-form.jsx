/**
 * Exemplo: Formulário acessível completo
 *
 * Padrões aplicados:
 * - <label> associado via for/id (nunca apenas placeholder)
 * - autocomplete obrigatório para dados pessoais (SC 1.3.5 AA)
 * - autocomplete="new-password" em senha (não "off")
 * - Erros: texto + ícone (não apenas cor), aria-describedby, aria-invalid
 * - aria-live="polite" para anunciar erros de forma não-intrusiva
 * - inputmode correto por tipo de campo
 * - Formato de campo comunicado antes do erro (SC 3.3.2)
 * - Botão de submit: min-h-[44px], aria-busy durante envio
 */

import { useState } from 'react';

function CadastroForm({ onSubmit }) {
  const [fields, setFields] = useState({ name: '', email: '', password: '' });
  const [errors, setErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const validate = () => {
    const next = {};
    if (!fields.name.trim()) next.name = 'Nome é obrigatório.';
    if (!fields.email.includes('@')) next.email = 'Informe um e-mail válido (ex.: usuario@dominio.com).';
    if (fields.password.length < 8) next.password = 'A senha deve ter no mínimo 8 caracteres.';
    return next;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const next = validate();
    setErrors(next);
    if (Object.keys(next).length > 0) return;

    setIsSubmitting(true);
    try {
      await onSubmit(fields);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} noValidate className="flex flex-col gap-6 max-w-md w-full">
      <h1 className="text-fg-primary text-2xl font-semibold">Criar conta</h1>

      {Object.keys(errors).length > 0 && (
        <div role="alert" aria-live="polite" className="p-4 rounded-lg bg-error-bg border border-error-border">
          <p className="text-error-fg text-sm font-medium">
            Corrija os erros abaixo para continuar.
          </p>
        </div>
      )}

      <div className="flex flex-col gap-1">
        <label htmlFor="name" className="text-fg-primary text-sm font-medium">
          Nome completo
        </label>
        <input
          id="name"
          name="name"
          type="text"
          autoComplete="name"
          aria-invalid={!!errors.name}
          aria-describedby={errors.name ? 'name-error' : undefined}
          value={fields.name}
          onChange={(e) => setFields((f) => ({ ...f, name: e.target.value }))}
          className={`rounded-lg border px-3 py-2 text-fg-primary bg-surface-input
                      focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2
                      focus-visible:outline-brand-primary
                      ${errors.name ? 'border-error-border' : 'border-border-default'}`}
        />
        {errors.name && (
          <p id="name-error" role="alert" className="text-error-fg text-xs flex items-center gap-1">
            <span aria-hidden="true">⚠</span> {errors.name}
          </p>
        )}
      </div>

      <div className="flex flex-col gap-1">
        <label htmlFor="email" className="text-fg-primary text-sm font-medium">
          E-mail
        </label>
        <input
          id="email"
          name="email"
          type="email"
          autoComplete="email"
          inputMode="email"
          aria-invalid={!!errors.email}
          aria-describedby={errors.email ? 'email-error' : 'email-hint'}
          value={fields.email}
          onChange={(e) => setFields((f) => ({ ...f, email: e.target.value }))}
          className={`rounded-lg border px-3 py-2 text-fg-primary bg-surface-input
                      focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2
                      focus-visible:outline-brand-primary
                      ${errors.email ? 'border-error-border' : 'border-border-default'}`}
        />
        <p id="email-hint" className="text-fg-secondary text-xs">
          Exemplo: usuario@dominio.com
        </p>
        {errors.email && (
          <p id="email-error" role="alert" className="text-error-fg text-xs flex items-center gap-1">
            <span aria-hidden="true">⚠</span> {errors.email}
          </p>
        )}
      </div>

      <div className="flex flex-col gap-1">
        <label htmlFor="password" className="text-fg-primary text-sm font-medium">
          Senha
        </label>
        <p id="password-hint" className="text-fg-secondary text-xs">
          Mínimo de 8 caracteres.
        </p>
        <input
          id="password"
          name="password"
          type="password"
          autoComplete="new-password"
          aria-invalid={!!errors.password}
          aria-describedby={errors.password ? 'password-error' : 'password-hint'}
          value={fields.password}
          onChange={(e) => setFields((f) => ({ ...f, password: e.target.value }))}
          className={`rounded-lg border px-3 py-2 text-fg-primary bg-surface-input
                      focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2
                      focus-visible:outline-brand-primary
                      ${errors.password ? 'border-error-border' : 'border-border-default'}`}
        />
        {errors.password && (
          <p id="password-error" role="alert" className="text-error-fg text-xs flex items-center gap-1">
            <span aria-hidden="true">⚠</span> {errors.password}
          </p>
        )}
      </div>

      <button
        type="submit"
        disabled={isSubmitting}
        aria-busy={isSubmitting}
        className="min-h-[44px] px-6 py-2 bg-brand-primary text-fg-on-brand rounded-lg font-medium
                   hover:bg-brand-primary-hover active:scale-[0.98]
                   disabled:opacity-50 disabled:pointer-events-none
                   focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2
                   focus-visible:outline-brand-primary"
      >
        {isSubmitting ? 'Criando conta...' : 'Criar conta'}
      </button>
    </form>
  );
}

export default CadastroForm;
