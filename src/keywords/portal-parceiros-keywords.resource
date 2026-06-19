*** Settings ***
Library       BuiltIn
Library       Browser
Library       Collections

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