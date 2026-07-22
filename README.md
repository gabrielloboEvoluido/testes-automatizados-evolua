## Executar o comando 

```
pip install -r requirements-dev.txt
```

## Variáveis de ambiente (.env)

O projeto lê as configurações de um arquivo `.env` na raiz (não versionado).
Além das URLs e credenciais, há uma variável opcional:

- `BROWSER_EXECUTABLE_PATH` — caminho de um navegador instalado no sistema
  (ex.: `C:/Program Files/Google/Chrome/Application/chrome.exe`). Se **vazia
  ou ausente**, os testes usam o chromium empacotado do Playwright (padrão,
  recomendado em CI). Defina-a apenas em máquinas onde o chromium empacotado
  não inicia — por exemplo, quando falta a dependência `msvcp140_1.dll`
  (Microsoft Visual C++ Redistributable) no Windows.