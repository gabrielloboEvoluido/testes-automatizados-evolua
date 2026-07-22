*** Settings ***
Library       BuiltIn
Library       Browser
Library       Collections
Resource      salesforce-keywords.resource

*** Keywords ***

REALIZAR LOGIN PORTAL DOS PARCEIROS
    [Arguments]    ${email}    ${password}

    Wait For Elements State    //input[@placeholder='E-mail']    visible    10s
    Fill Text    //input[@placeholder='E-mail']    ${email}

    Wait For Elements State    //input[@placeholder='Insira sua senha']    visible    10s
    Fill Text    //input[@placeholder='Insira sua senha']    ${password}

    Wait For Elements State    //button[text()='Avançar']    visible    10s
    Click    //button[text()='Avançar']

SELECIONAR MODULO PORTAL DOS PARCEIROS
    [Arguments]    ${modulo}

    @{modulos_disponiveis}=    Create List
    ...     Simular economia
    ...     Fazer contratação
    ...     Acompanhar o Funil
    ...     Acompanhar Vendas
    ...     Acompanhar Leads

    ${contem_modulo}=    Run Keyword And Return Status
    ...    List Should Contain Value
    ...    ${modulos_disponiveis}
    ...    ${modulo}

    IF    ${contem_modulo}
            Wait For Elements State     //span[text()='${modulo}']      visible     10s
            Click   //span[text()='${modulo}']
    ELSE
        Log To Console    Modulo informado não encontrado.
    END

PREENCHER FORMULARIO BENEFICIO PORTAL DOS PARCEIROS
    [Arguments]     
        ...     ${name}
        ...     ${cpf}
        ...     ${email}
        ...     ${celular}

    Wait For Elements State     //input[@placeholder='Nome completo do titular da conta']       visible     10s
    Fill Text   //input[@placeholder='Nome completo do titular da conta']       ${name}
    Fill Text   //input[@placeholder='Insira o CPF ou CNPJ do titular']       ${cpf}
    Fill Text   //input[@placeholder='E-mail para contato do titular']       ${email}
    Fill Text   //input[@placeholder='DDD + Número do celular']       ${celular}

    Wait For Elements State     //button[text()='Avançar']      visible     10s
    Click   //button[text()='Avançar']


VALIDAR TELA ACOMPANHAR LEADS
    Wait For Elements State
    ...    text=Leads Dashboard
    ...    visible
    ...    20s

    Wait For Elements State
    ...    input[placeholder="Buscar"]
    ...    visible
    ...    20s

    AGUARDAR CARREGAMENTO DO KANBAN


AGUARDAR CARREGAMENTO DO KANBAN
    [Documentation]
    ...    Aguarda o quadro Kanban renderizar antes das validações. As
    ...    keywords de validação usam Get Element Count, que NÃO espera; sem
    ...    esta sincronização o teste roda contra a página ainda vazia e
    ...    encerra antes do conteúdo aparecer.
    ...
    ...    Usa polling por contagem (Get Element Count, que não sofre com o
    ...    strict mode do Wait For Elements State — o seletor casa com várias
    ...    colunas). Assim que ao menos uma coluna aparece na tela, segue.

    Wait Until Keyword Succeeds    30s    1s    KANBAN POSSUI COLUNAS


KANBAN POSSUI COLUNAS
    [Documentation]
    ...    Falha (para o retry do Wait Until Keyword Succeeds) enquanto
    ...    nenhuma coluna do Kanban estiver presente na tela.

    ${qtd}=    Get Element Count
    ...    xpath=//div[contains(@class,'rounded-xl')]

    Should Be True
    ...    ${qtd} > 0
    ...    O quadro Kanban ainda não carregou (nenhuma coluna visível).

    RETURN    ${qtd}


OBTER COLUNAS KANBAN
    @{colunas}=    Create List
    ...    Novo
    ...    Upload conta de energia
    ...    Elegibilidade Manual
    ...    Seleção do plano
    ...    Envio de proposta
    ...    Upload de documentos da empresa
    ...    Upload de documentos pessoais
    ...    Cadastro de contato comercial
    ...    Cadastro de representante legal
    ...    Cadastro de contato financeiro
    ...    Seleção de forma de pagamento
    ...    Aguardando documentação de representantes
    ...    Desqualificado
    ...    Não Qualificado
    ...    Inelegível
    ...    Convertido
    ...    Qualificado
    ...    Aguardando Assinatura

    RETURN    @{colunas}


COLUNA KANBAN EXISTE
    [Arguments]    ${coluna}

    ${qtd}=    Get Element Count
    ...    xpath=//span[normalize-space()='${coluna}']

    ${existe}=    Evaluate    ${qtd} > 0

    RETURN    ${existe}


VALIDAR COLUNAS KANBAN
    @{colunas}=    OBTER COLUNAS KANBAN

    FOR    ${coluna}    IN    @{colunas}
        ${existe}=    COLUNA KANBAN EXISTE    ${coluna}

        IF    ${existe}
            Log To Console
            ...    ✓ Coluna encontrada: ${coluna}
        ELSE
            Log To Console
            ...    Coluna não exibida: ${coluna}
        END
    END


CONTAR CARDS EM TODAS AS COLUNAS KANBAN
    @{colunas}=    OBTER COLUNAS KANBAN

    FOR    ${coluna}    IN    @{colunas}
        ${existe}=    COLUNA KANBAN EXISTE    ${coluna}

        IF    not ${existe}
            Log To Console
            ...    Coluna "${coluna}" não encontrada. Ignorando...
            CONTINUE
        END

        ${qtd}=    Get Element Count
        ...    xpath=//span[normalize-space()='${coluna}']/ancestor::div[contains(@class,'rounded-xl')][1]//div[contains(@class,'bg-white') and contains(@class,'rounded-lg') and contains(@class,'shadow-sm')]

        Log To Console
        ...    ${coluna}: ${qtd} card(s)
    END


VALIDAR DADOS DO CARD EM TODAS AS COLUNAS
    @{colunas}=    OBTER COLUNAS KANBAN

    FOR    ${coluna}    IN    @{colunas}
        ${existe}=    COLUNA KANBAN EXISTE    ${coluna}

        IF    not ${existe}
            Log To Console
            ...    Coluna "${coluna}" não encontrada. Ignorando...
            CONTINUE
        END

        ${qtd}=    Get Element Count
        ...    xpath=//span[normalize-space()='${coluna}']/ancestor::div[contains(@class,'rounded-xl')][1]//div[contains(@class,'bg-white') and contains(@class,'rounded-lg') and contains(@class,'shadow-sm')]

        Log To Console
        ...    Validando ${qtd} card(s) da coluna ${coluna}

        FOR    ${i}    IN RANGE    1    ${qtd + 1}
            ${base}=    Set Variable
            ...    (//span[normalize-space()='${coluna}']/ancestor::div[contains(@class,'rounded-xl')][1]//div[contains(@class,'bg-white') and contains(@class,'rounded-lg') and contains(@class,'shadow-sm')])[${i}]

            Run Keyword And Continue On Failure
            ...    VALIDAR CARD KANBAN
            ...    ${base}
        END
    END


VALIDAR CARD KANBAN
    [Documentation]
    ...    Valida um único card do Kanban (formato dos dados exibidos +
    ...    nome no Salesforce). Chamada via "Run Keyword And Continue On
    ...    Failure" para que a divergência de um card não impeça a
    ...    validação dos demais cards/colunas na mesma execução.
    [Arguments]    ${base}

    ${nome_card}=    Get Text
    ...    xpath=${base}//p

    ${email}=    Get Text
    ...    xpath=${base}//span[contains(@class,'break-words')]

    ${telefone}=    Get Text
    ...    xpath=${base}//img[contains(@src,'phone.svg')]/following-sibling::span

    ${data}=    Get Text
    ...    xpath=${base}//img[contains(@src,'calendar.svg')]/following-sibling::span

    ${kwh}=    Get Text
    ...    xpath=${base}//img[contains(@src,'energy.svg')]/following-sibling::span

    Should Not Be Empty
    ...    ${nome_card}
    ...    O nome do card está vazio.

    Should Not Be Empty
    ...    ${email}
    ...    O e-mail do card está vazio.

    Should Not Be Empty
    ...    ${telefone}
    ...    O telefone do card está vazio.

    Should Match Regexp
    ...    ${data}
    ...    \\d{2}/\\d{2}/\\d{4}
    ...    A data do card possui formato inválido.

    Should Match Regexp
    ...    ${kwh}
    ...    \\d+(\.\\d+)?\\s*kWh
    ...    O consumo do card possui formato inválido.

    TRY
        ${cpf}    ${nome_portal}=    ABRIR CARD E CAPTURAR CPF
        ...    ${base}

        Log To Console
        ...    Validando Lead ${nome_portal} (${cpf})

        VALIDAR LEAD SALESFORCE
        ...    ${cpf}
        ...    ${nome_portal}
    FINALLY
        FECHAR DETALHE DO LEAD
    END


VALIDAR LEAD SALESFORCE
    [Documentation]
    ...    Valida o nome do Lead exibido no card do portal contra os
    ...    registros do Salesforce para o mesmo CPF/CNPJ.
    ...
    ...    Pode existir mais de um Lead para o mesmo CPF (ex.: recadastro
    ...    após correção de um Lead anterior com dados errados). Por isso a
    ...    validação é considerada OK se o nome do portal corresponder a
    ...    QUALQUER UM dos Leads retornados, e só falha se não houver
    ...    nenhuma correspondência.
    [Arguments]    ${cpf}    ${nome_portal}

    @{leads}=    BUSCAR LEADS POR CPF    ${cpf}

    ${qtd_leads}=    Get Length    ${leads}

    IF    ${qtd_leads} > 1
        Log To Console
        ...    ⚠ ${qtd_leads} leads encontrados no Salesforce para o CPF ${cpf} (possível duplicidade)
    END

    ${encontrado}=    Set Variable    ${False}
    @{nomes_encontrados}=    Create List

    FOR    ${lead}    IN    @{leads}
        ${nome_salesforce}=    Set Variable    ${lead}[Name]
        Append To List    ${nomes_encontrados}    ${nome_salesforce}

        ${confere}=    Run Keyword And Return Status
        ...    Should Be Equal As Strings
        ...    ${nome_portal}
        ...    ${nome_salesforce}
        ...    ignore_case=True
        ...    strip_spaces=True
        ...    collapse_spaces=True

        IF    ${confere}
            ${encontrado}=    Set Variable    ${True}
            BREAK
        END
    END

    IF    not ${encontrado}
        ${nomes_exibidos}=    Set Variable    ${nomes_encontrados}

        IF    ${qtd_leads} > 10
            @{nomes_exibidos}=    Get Slice From List    ${nomes_encontrados}    0    10
            ${restantes}=    Evaluate    ${qtd_leads} - 10
            Append To List    ${nomes_exibidos}    ... e mais ${restantes} nome(s)
        END

        Fail
        ...    Nome divergente. Portal: "${nome_portal}" | Nenhum dos ${qtd_leads} lead(s) do Salesforce corresponde: ${nomes_exibidos}
    END

    Log To Console
    ...    ✓ Lead validado: ${nome_portal}


ABRIR CARD E CAPTURAR CPF
    [Arguments]    ${base}

    Click    xpath=${base}

    Wait For Elements State
    ...    xpath=//label[normalize-space()='CPF/CNPJ:']/following-sibling::input
    ...    visible
    ...    10s

    ${cpf}=    Get Attribute
    ...    xpath=//label[normalize-space()='CPF/CNPJ:']/following-sibling::input
    ...    value

    ${primeiro_nome}=    Get Attribute
    ...    xpath=//label[normalize-space()='Primeiro nome:']/following-sibling::input
    ...    value

    ${sobrenome}=    Get Attribute
    ...    xpath=//label[normalize-space()='Sobrenome:']/following-sibling::input
    ...    value

    ${nome}=    Set Variable
    ...    ${primeiro_nome} ${sobrenome}

    Should Not Be Empty
    ...    ${cpf}
    ...    O CPF/CNPJ do Lead está vazio.

    Should Not Be Empty
    ...    ${nome}
    ...    O nome do Lead está vazio.

    Log To Console
    ...    CPF/CNPJ: ${cpf}

    Log To Console
    ...    Nome: ${nome}

    RETURN    ${cpf}    ${nome}


FECHAR DETALHE DO LEAD
    Wait For Elements State
    ...    xpath=//button[.//*[name()='svg' and contains(@class,'lucide-x')]]
    ...    visible
    ...    5s

    Click
    ...    xpath=//button[.//*[name()='svg' and contains(@class,'lucide-x')]]

    Wait For Elements State
    ...    xpath=//label[normalize-space()='CPF/CNPJ:']/following-sibling::input
    ...    hidden
    ...    5s