#!/usr/bin/env python3
"""Uso: python plan_lint.py plano.md  (saída 0 = sem falhas mecânicas; 1 = há falhas)."""
import re
import sys

CAMPOS = ("Cobre:", "Depende de:", "Arquivos:", "Verificação:",
          "Pronto quando:", "Commit:", "Se falhar:")
CAMPOS_CODIGO = ("Consome:", "Produz:")
CABECALHO = ("Objetivo", "Fora de escopo", "Stack e versões", "Comandos exatos",
             "Regras inegociáveis", "Decisões já tomadas", "Mapa de arquivos",
             "Estado base", "Executor e nível de detalhe", "PARADA — Tarefa")
PROIBIDOS = (r"\bTODO\b", r"\betc\b", r"\.\.\.", r"[Ss]imilar à [Tt]arefa",
             r"[Cc]omo antes", r"[Ii]mplemente a lógica", r"\bregra \d+\b")
PERIGOSOS = (r"git push", r"reset --hard", r"git clean\s+-f", r"--force", r"--no-verify",
             r"rm -rf", r"\bsudo\b", r"curl[^\n]*\|\s*(ba)?sh", r"\bDROP\b", r"\bTRUNCATE\b")
SEGREDOS = (r"sk-[A-Za-z0-9]{20,}", r"AKIA[0-9A-Z]{16}",
            r"(?i)(api[_-]?key|token|secret|password)\s*[:=]\s*['\"]?[A-Za-z0-9/+_\-]{16,}")
ID_CRITERIO = re.compile(r"\bR\d+\.AC\d+\b")


def contar_arquivos(linha):
    # 1 arquivo por segmento separado por '|'; âncoras em backticks não contam.
    return sum(1 for seg in linha.split("|") if re.search(r"`[^`]+`", seg))


def main(caminho):
    texto = open(caminho, encoding="utf-8").read()
    erros = []

    sem_codigo = re.sub(r"```.*?```", "", texto, flags=re.S)
    for padrao in PROIBIDOS:
        for m in re.finditer(padrao, sem_codigo):
            erros.append(f"placeholder ou referência vaga: '{m.group(0)}'")
    for padrao in SEGREDOS:
        if re.search(padrao, texto):
            erros.append("possível segredo literal no plano")

    partes = re.split(r"(?m)^### Tarefa (\d+)\b", texto)
    tarefas = {int(partes[i]): re.split(r"\n#{1,2} ", partes[i + 1])[0]
               for i in range(1, len(partes) - 1, 2)}
    if not tarefas:
        erros.append("nenhuma seção '### Tarefa N' encontrada")
    elif 0 not in tarefas:
        erros.append("Tarefa 0 (pré-checagem do estado base) ausente")

    for item in CABECALHO:
        if item not in texto:
            erros.append(f"cabeçalho/protocolo: '{item}' ausente")
    if "Você é o executor" not in texto:
        erros.append("bloco 'Instruções ao executor' ausente")
    if not re.search(r"(?i)requisito\s*→\s*tarefas|rastreabilidade", texto):
        erros.append("tabela requisito → tarefas ausente")

    for n, corpo in tarefas.items():
        for campo in CAMPOS + (CAMPOS_CODIGO if n != 0 else ()):
            if campo not in corpo:
                erros.append(f"Tarefa {n}: campo ausente '{campo}'")
        dep = re.search(r"Depende de:\s*(.+)", corpo)
        if dep:
            for d in re.findall(r"[Tt]arefa\s+(\d+)", dep.group(1)):
                if int(d) >= n:
                    erros.append(f"Tarefa {n}: depende da Tarefa {d} (não anterior)")
        arq = re.search(r"Arquivos:\s*(.+)", corpo)
        if arq and contar_arquivos(arq.group(1)) > 3:
            erros.append(f"Tarefa {n}: mais de 3 arquivos (só se for operação mecânica)")
        passos = re.search(r"Passos:(.*?)(?=\nVerificação:)", corpo, flags=re.S)
        if passos and len(re.findall(r"(?m)^\d+\.\s", passos.group(1))) > 8:
            erros.append(f"Tarefa {n}: mais de 8 passos")
        for padrao in PERIGOSOS:
            if re.search(padrao, corpo) and "[IRREVERSÍVEL]" not in corpo:
                erros.append(f"Tarefa {n}: comando perigoso '{padrao}' sem [IRREVERSÍVEL]")
        if "[IRREVERSÍVEL]" in corpo and "CONFIRMAÇÃO" not in corpo \
                and "ambiente descartável" not in texto:
            erros.append(f"Tarefa {n}: [IRREVERSÍVEL] sem CONFIRMAÇÃO nem ambiente descartável")

    if len([n for n in tarefas if n > 0]) > 5 and "### Checkpoint" not in texto:
        erros.append("plano com mais de 5 tarefas sem '### Checkpoint K'")

    todos = set(ID_CRITERIO.findall(texto))
    cobertos = set()
    for m in re.finditer(r"Cobre:\s*(.+)", texto):
        cobertos |= set(ID_CRITERIO.findall(m.group(1)))
    for ac in sorted(todos - cobertos):
        erros.append(f"critério sem tarefa: {ac}")

    for e in erros:
        print("FALHA:", e)
    print("OK" if not erros else f"{len(erros)} falha(s)")
    return 1 if erros else 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("uso: python plan_lint.py plano.md")
    sys.exit(main(sys.argv[1]))
