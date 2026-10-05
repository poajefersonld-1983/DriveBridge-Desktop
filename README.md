# DriveBridge-Desktop

Aplicativo de sincronização do Google Drive para Linux, escrito em Python, com interface desktop Tkinter. Usa diretamente a Google Drive API v3, sem rclone.

**Versão inicial para a comunidade.** Cada instalação usa suas próprias contas e configurações. Este repositório não inclui contas Google, clientes OAuth, tokens, senhas, pastas pessoais ou logs reais.

## Recursos

- Múltiplas contas Google e pares de pastas locais/remotas.
- Local → Drive, Drive → Local e sincronização bidirecional.
- Navegação pelas pastas locais do computador e pastas remotas do Drive. `root` representa todo o Meu Drive.
- Progresso por bytes confirmados, arquivos ativos, taxa total e média.
- Transferências paralelas: 4 arquivos × blocos de 16 MiB, sem limitador de MiB/s.

## Baixar e instalar com um comando

```bash
curl -fsSL https://raw.githubusercontent.com/poajefersonld-1983/DriveBridge-Desktop/main/install.sh -o drivebridge-desktop-install.sh && bash drivebridge-desktop-install.sh
```

Execute como usuário normal, com `curl` instalado. O instalador solicita sudo para dependências e baixa o projeto para `~/DriveBridge-Desktop`. Uma pasta de outro projeto ou com alterações não é sobrescrita. Para escolher outro destino, defina `DRIVEBRIDGE_INSTALL_DIR` ao executar o script. Cada pessoa conecta sua própria conta Google após instalar.

Esta distribuição contém somente o app desktop, sem Flask, servidor web ou serviço systemd. A outra versão está em [DriveBridge-Web](https://github.com/poajefersonld-1983/DriveBridge-Web).

## Requisitos e instalação

Python 3.10 ou superior. Testado em Fedora e Debian. Tenha Git e acesso à internet para instalar as dependências Python.

Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y git python3 python3-venv python3-tk
```

Fedora:

```bash
sudo dnf install -y git python3 python3-tkinter
```

Baixe o projeto:

```bash
git clone https://github.com/poajefersonld-1983/DriveBridge-Desktop.git
cd DriveBridge-Desktop
python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
```

### Desktop

```bash
.venv/bin/python -m pip install -e .
./iniciar.sh
```

Para instalar o atalho no menu de aplicativos e no desktop:

```bash
./tools/install-desktop.sh
```

## Conectar sua própria conta Google

O repositório não traz um cliente OAuth pronto. Cada pessoa configura seu projeto Google Cloud:

1. Crie ou selecione um projeto no [Google Cloud](https://console.cloud.google.com/).
2. Habilite a **Google Drive API** nesse projeto.
3. Configure o consentimento no Google Auth Platform: marca, público e acesso aos dados. Para uso pessoal em teste, adicione sua conta como usuário de teste.
4. Crie um cliente OAuth do tipo **Aplicativo para computador** e baixe o JSON.
5. Abra **Adicionar conta** no DriveBridge, informe seu e-mail e importe o JSON na configuração avançada.
6. Autorize no navegador. O aplicativo salva a conta efetivamente autorizada, mesmo se for diferente do e-mail inicialmente informado.

E-mail sozinho não permite acessar o Drive. O JSON cadastra o aplicativo; a autorização do navegador concede acesso à conta. Não envie esse JSON nem seus tokens a este repositório.

O escopo atual é `https://www.googleapis.com/auth/drive`, necessário para navegar e sincronizar arquivos existentes. Projetos compartilhados para distribuição pública devem cumprir as [regras de escopos e verificação do Google](https://developers.google.com/workspace/drive/api/guides/api-specific-auth). Publicar o código não significa que um cliente OAuth coletivo já está aprovado.

## Criar e sincronizar um par

1. Selecione a conta Google.
2. Informe o nome do par e escolha uma pasta local existente.
3. Navegue até a pasta remota ou mantenha `root` para todo o Meu Drive.
4. Escolha a direção. Em uma primeira sincronização bidirecional, arquivos de mesmo caminho com conteúdos diferentes são sinalizados como conflito.
5. Salve o par e clique em **Sincronizar agora**.

### Agendamento

Ative o agendamento do par e escolha o intervalo em minutos. O aplicativo deve permanecer aberto. A sincronização bidirecional compara conteúdo e histórico e sinaliza alterações simultâneas. Exclusões não são propagadas; renomes são tratados como arquivos novos.

## Progresso e desempenho

A varredura do Drive e a leitura dos checksums locais ocorrem antes de calcular o total. Nessa etapa, a barra é indeterminada. Durante transferências, percentual e taxas usam bytes confirmados pela API; confirmações chegam por bloco, portanto a taxa pode oscilar e a barra pode ficar estável entre blocos. Isso não mede tráfego instantâneo da placa de rede.

Cada trabalhador reutiliza sua própria conexão HTTP. Arquivos distintos transferem em paralelo; cada arquivo grande usa uma conexão. Uploads são retomáveis durante a execução, mas não há retomada por blocos após fechar o processo. Downloads usam arquivo temporário, checksum e substituição após verificação.

Aumentar concorrência/blocos pode ajudar ou piorar o desempenho e aumenta memória. Não há garantia de atingir toda a conexão contratada. Varredura, armazenamento, CPU, latência e [limites da API do Google](https://developers.google.com/workspace/drive/api/guides/limits) influenciam o resultado.

## Dados locais e privacidade

Por padrão, os dados privados ficam **fora do projeto**, em `~/.config/drivebridge-desktop/`; `XDG_CONFIG_HOME` pode definir outro diretório:

| Arquivo/pasta | Conteúdo privado |
| --- | --- |
| `oauth-client.json` | Configuração do seu cliente OAuth |
| `accounts.json`, `tokens/` | Contas e tokens Google |
| `profiles.json`, `states/` | Pares e checkpoints |

Arquivos de credenciais são protegidos por permissões de sistema (0600), **sem criptografia em repouso ou keyring**. Não compartilhe a pasta privada. Tokens são usados diretamente no Google; transferências não passam por um servidor do projeto.

Não adicione senhas, tokens, e-mails pessoais, logs reais ou capturas com dados de contas a issues e pull requests. Consulte [SECURITY.md](SECURITY.md).

## Limitações atuais

- Documentos nativos Google Docs/Sheets/Slides, atalhos, links simbólicos, nomes ambíguos/incompatíveis e caminhos inacessíveis são ignorados e registrados. Seus caminhos são reservados para evitar colisões.
- Não sincroniza pastas vazias ou unidades compartilhadas; não há exclusão espelhada, bandeja, keyring ou pacote RPM/Flatpak.
- Apenas uma sincronização ativa por instalação. Não inicie o desktop e o serviço web simultaneamente usando os mesmos tokens, pares e checkpoints.
- Falhas individuais ficam pendentes; falhas globais (sem espaço, autorização, rede persistente ou quota) interrompem a operação preservando o que terminou.
- Para revogar uma conta, use as permissões de aplicativos na conta Google. A interface ainda não remove contas.

## Desenvolvimento e testes

```bash
.venv/bin/python -m pip install -e .
.venv/bin/python -m unittest discover -s tests -v
.venv/bin/python -m compileall -q drivebridge
```

Os testes usam arquivos temporários e mocks de Google: não contêm uma conta real, não enviam e-mails reais e não medem velocidade real de rede. Cobrem conflitos, falhas, concorrência, progresso, autenticação e interface desktop. Veja [CONTRIBUTING.md](CONTRIBUTING.md).

## Licença

MIT. Veja [LICENSE](LICENSE). Este projeto é independente e não é afiliado ao Google, Insync ou rclone.

O aplicativo usa configurações em `~/.config/drivebridge-desktop/`, separadas do serviço web e da instalação antiga. Nenhuma configuração antiga é importada automaticamente.

Instale cada versão em sua própria pasta e ambiente virtual `.venv`; os dois pacotes usam o módulo Python `drivebridge` e não devem ser instalados no mesmo ambiente virtual.
