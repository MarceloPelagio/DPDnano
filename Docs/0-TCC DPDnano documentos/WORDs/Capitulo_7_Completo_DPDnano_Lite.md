# CAPÍTULO 7 - VALIDAÇÃO EM HARDWARE DO DPDNANO-LITE

## 7.1 Introdução

Após a consolidação da arquitetura RTL e da verificação funcional em ambiente controlado, a etapa seguinte do desenvolvimento consistiu na validação experimental do DPDnano-Lite diretamente em FPGA. O objetivo deste capítulo é documentar, com rigor técnico, a campanha de testes de hardware realizada sobre a plataforma Tang Nano 4K, descrevendo os procedimentos adotados, os critérios de aprovação, os resultados obtidos e as limitações observadas durante a operação do predistorcedor digital em tempo real.

A literatura de Predistorção Digital indica que a avaliação prática de um predistorcedor não pode se limitar à coerência algorítmica do modelo matemático, pois a implementação física impõe restrições próprias de representação numérica, temporização, paralelismo e consumo de recursos computacionais (DING et al., 2004; MORGAN et al., 2006; LI; MONTORO; GILABERT, 2024). Em arquiteturas compactas, como a proposta neste trabalho, tais restrições tornam-se ainda mais relevantes, uma vez que a estabilidade temporal da solução precisa coexistir com área limitada, largura de palavra reduzida e margens estreitas de temporização na FPGA-alvo (SIPEED, 2026).

Também é importante destacar que a campanha de validação foi organizada segundo uma lógica de verificação progressiva, em que cada ensaio exercia um papel específico dentro do processo de amadurecimento do sistema. Essa abordagem é coerente com a prática de verificação funcional incremental em projetos digitais, na qual a robustez de um sistema sintetizável é construída a partir da combinação entre critérios explícitos de aprovação, repetibilidade dos estímulos e observabilidade interna suficiente para isolar falhas de integração (BERGERON, 2000). Do ponto de vista temporal, os ensaios também buscaram estabelecer correlação entre o comportamento observado em execução real e os conceitos de previsibilidade de latência e consistência de caminho crítico discutidos na literatura de análise temporal estática (BHASKER; CHADHA, 2009).

Neste contexto, a bateria HW001 a HW024 foi definida como o eixo de validação em hardware do DPDnano-Lite. Os testes iniciais concentraram-se na infraestrutura de comunicação, depuração e integração host-FPGA. Em seguida, foram executados ensaios dedicados à caracterização AM/AM, AM/PM, saturação, overflow, compressão, ganho incremental, janela operacional e sensibilidade paramétrica. Por fim, a campanha foi encerrada com testes temporais, dinâmicos e estatísticos, voltados à demonstração de estabilidade operacional prolongada do sistema em FPGA real.

## 7.2 Organização da campanha experimental

Para tornar o pacote de testes reprodutível e coerente para uso acadêmico e posterior disponibilização em repositório, todos os ensaios foram reorganizados em subpastas independentes dentro de `src/testes_hardware_HWxxx`. Cada pasta passou a conter seu próprio script principal, arquivos de resultados, documentação local e pasta `rtl` com apenas os componentes particulares do respectivo ensaio. Os módulos compartilhados permaneceram centralizados em `src/common`, `src/gowin_pllvr` e `src/rtl_v3_1`, preservando separação clara entre infraestrutura global e lógica específica de teste.

Em termos metodológicos, a campanha foi estruturada em três grandes blocos: (i) ensaios de bring-up e infraestrutura, cobrindo HW001 a HW011; (ii) ensaios de caracterização funcional e não linear, cobrindo HW012 a HW021; e (iii) ensaios temporais, dinâmicos e estatísticos, cobrindo HW022 a HW024. Essa segmentação permitiu rastrear com clareza a evolução do projeto desde a confirmação da comunicação básica até a validação de robustez sob fluxo contínuo e repetição prolongada.

| Bloco de ensaio | Testes abrangidos | Finalidade principal |
| --- | --- | --- |
| Bring-up e integração | HW001 a HW011 | Validar UART, protocolo, memória auxiliar, top-levels de teste e infraestrutura de observação em FPGA |
| Caracterização do núcleo DPD | HW012 a HW021 | Medir curvas AM/AM e AM/PM, saturação, overflow, compressão, ganho incremental, janela operacional e sensibilidade aos coeficientes |
| Robustez temporal e dinâmica | HW022 a HW024 | Confirmar latência fixa, estabilidade de throughput, integridade de fluxo e reprodutibilidade estatística |

Do ponto de vista experimental, esse arranjo foi importante porque evitou tratar todos os testes como se tivessem o mesmo peso analítico. Os ensaios HW001 a HW011 sustentam a confiabilidade da plataforma; os ensaios HW012 a HW021 examinam diretamente o comportamento do DPD; e os ensaios HW022 a HW024 demonstram a maturidade temporal e operacional da solução proposta.

Para fins de redação científica, essa organização também foi importante porque permitiu separar claramente três níveis de evidência. O primeiro nível corresponde à infraestrutura experimental: sem ele, qualquer curva ou métrica posterior poderia ser contestada como possível artefato de comunicação, endereçamento ou controle. O segundo nível corresponde à evidência comportamental do próprio predistorcedor, isto é, à demonstração de que a arquitetura realmente implementa uma resposta polinomial controlada em hardware real. O terceiro nível corresponde à evidência sistêmica, na qual se mostra que a resposta não é apenas correta pontualmente, mas também sustentada ao longo do tempo, em campanhas extensas e repetidas.

Outro ganho dessa organização foi a possibilidade de rastrear causalidade entre os ensaios. Em vez de tratar HW012 a HW024 como um conjunto desconexo de figuras, o capítulo passa a mostrá-los como uma cadeia lógica: primeiro estabiliza-se a infraestrutura; depois observa-se a curva AM/AM e define-se a frequência operacional; em seguida validam-se saturação, fase, compressão, sensibilidade paramétrica e janela operacional; por fim, confirmam-se latência, throughput e reprodutibilidade. Essa progressão melhora a legibilidade do capítulo e também fortalece sua defesa perante uma banca, pois cada etapa passa a responder explicitamente a uma pergunta técnica do projeto.

Tabela 7.1 - Papel experimental dos ensaios centrais de caracterização em hardware

| Ensaio | Pergunta principal | Métrica central | Ganho analítico para o capítulo |
| --- | --- | --- | --- |
| HW012 | Qual a maior frequência com curva AM/AM fisicamente confiável? | Monotonicidade, overflow espúrio, saturação indevida | Delimita a frequência operacional validada |
| HW013 | Onde a representação Q1.15 impõe saturação e overflow? | Saída máxima e ocorrência de saturação | Define a fronteira numérica da arquitetura |
| HW014 | A multiplicação complexa interna gera rotação coerente? | Desvio de fase e trajetória I/Q | Valida o caminho complexo do núcleo |
| HW015 | O efeito AM/PM cresce de forma consistente com a amplitude? | Curva de fase por amplitude | Confirma dependência não linear de fase |
| HW016 | Perfis AM/PM distintos permanecem ordenados e reprodutíveis? | Comparação entre quatro perfis | Demonstra flexibilidade paramétrica |
| HW017 | Como ocorre a transição entre expansão, compressão e saturação? | Curva AM/AM em regime forte | Expõe a geometria global da resposta |
| HW018 | Em que ponto a compressão ultrapassa 1 dB? | Ponto de compressão de 1 dB | Quantifica a faixa útil de operação |
| HW019 | Quando a derivada da curva se anula ou se torna negativa? | Ganho incremental | Introduz a não monotonicidade como limitante |
| HW020 | Como a resposta muda no plano bidimensional de coeficientes? | Mapas de status, pico e saturação | Delimita a janela operacional do projeto |
| HW021 | Qual a sensibilidade da curva a pequenas variações de `coef1` e `coef3`? | Famílias de curvas e deltas | Explica a influência relativa dos parâmetros |
| HW022 | A latência permanece invariável sob diferentes tráfegos? | Latência e jitter | Valida determinismo temporal |
| HW023 | O sistema sustenta fluxo contínuo longo e dinâmico? | Throughput, checkpoints, integridade | Demonstra robustez operacional prolongada |
| HW024 | O comportamento se repete estatisticamente entre execuções? | Média e dispersão entre runs | Consolida a reprodutibilidade experimental |

## 7.3 Plataforma de hardware e configuração de execução

Todos os ensaios descritos neste capítulo foram realizados sobre a placa Tang Nano 4K, escolhida por representar um cenário de FPGA compacta e de recursos limitados, adequado ao objetivo central do DPDnano-Lite: demonstrar a viabilidade de uma arquitetura de Predistorção Digital especializada, compacta e tecnicamente rastreável em hardware reconfigurável de pequeno porte (SIPEED, 2026). Ao adotar deliberadamente uma plataforma restritiva, o trabalho se afasta de soluções baseadas em abundância de DSPs e memória e enfatiza o mérito arquitetural da simplificação do modelo polinomial (LI; MONTORO; GILABERT, 2024).

O núcleo de processamento utilizado como referência final nesta etapa foi a versão `rtl_v3_1`, previamente congelada após a conclusão das etapas de desenvolvimento arquitetural e implementação RTL. Sobre esse núcleo foram construídos top-levels específicos de teste, interfaces UART, lógica de controle, módulos de observação e instrumentação de apoio para leitura de métricas, checkpoints e resultados agregados. A conexão com o computador hospedeiro foi feita por interface serial USB/TTL, com scripts Python responsáveis por aplicar estímulos, monitorar o estado do hardware e consolidar os CSVs de cada ensaio.

Embora a formulação do predistorcedor derive da classe de modelos Memory Polynomial e de suas extensões correlatas (DING et al., 2004; MORGAN et al., 2006), a implementação prática exigiu que essa formulação fosse reinterpretada à luz de restrições físicas de clock, largura de palavra e estrutura de pipeline. Por isso, a avaliação em hardware foi tão importante quanto a formulação matemática: somente os resultados experimentais permitiram delimitar, de forma objetiva, a faixa de operação realmente estável do projeto.

Do ponto de vista de bancada, a campanha foi conduzida de forma a maximizar a reprodutibilidade. Os bitstreams eram gravados na FPGA antes de cada grupo de ensaios relevantes, os scripts host eram executados com parâmetros explícitos de porta serial e amplitude máxima, e os resultados eram sempre salvos localmente em arquivos CSV independentes por teste. Esse procedimento teve valor metodológico importante: ele reduziu a dependência de observações manuais e permitiu que as conclusões do capítulo fossem apoiadas em dados persistidos, comparáveis e passíveis de reinspeção posterior.

Também merece destaque o fato de que os top-levels de teste não foram tratados como simples artefatos descartáveis. Cada ensaio de hardware foi organizado para permanecer independente e reexecutável, com seus próprios scripts, documentação local, imagens e, quando necessário, arquivos particulares de RTL. Essa escolha foi relevante tanto para a escrita do TCC quanto para a futura disponibilização pública do projeto, pois aproxima a campanha de uma metodologia de laboratório reprodutível, em vez de uma sequência ad hoc de experimentos.

Em termos temporais, a presença do PLL foi decisiva para a campanha. A placa fornece clock de referência de 27 MHz, e o uso do PLL interno permitiu explorar faixas superiores de operação do núcleo DPD. Entretanto, como será discutido nas seções seguintes, a mera configuração nominal do PLL não garantiu validade experimental do processamento. A campanha mostrou, com clareza, que existe diferença entre selecionar uma frequência alvo no gerador de clock e demonstrar que a arquitetura permanece funcionalmente íntegra naquela condição.

## 7.4 Procedimento de validação e critérios de aprovação

Os scripts host empregados na campanha foram concebidos para operar como instrumentos de verificação autoavaliável. Em cada ensaio, eram definidos critérios explícitos de `PASS` ou `FAIL`, baseados em coerência de resposta, ausência de perdas, estabilidade temporal, limites de saturação, monotonicidade ou comparação entre medições sucessivas. Essa filosofia aproxima a campanha do conceito de testbench orientado a verificação funcional, ainda que executado aqui sobre hardware real em vez de apenas simulação comportamental (BERGERON, 2000).

No bloco inicial de ensaios, os critérios de aprovação estavam associados principalmente à confiabilidade da comunicação com a FPGA, ao retorno correto de bytes esperados, à persistência de dados escritos em memória auxiliar, à resposta consistente de sinais de depuração e ao funcionamento elementar da infraestrutura de controle. Já nos ensaios de caracterização do núcleo DPD, os critérios passaram a incorporar elementos diretamente ligados à teoria da predistorção, como transição para saturação, preservação de monotonicidade, evolução do ganho incremental, desvio de fase dependente da amplitude e deslocamento da curva em função dos coeficientes reais e complexos do modelo.

Nos testes temporais e dinâmicos, por sua vez, a aprovação passou a depender de métricas como latência mínima e máxima, jitter, throughput, ausência de perdas, ausência de duplicações, ausência de reordenação e consistência entre checkpoints de processamento. Esse conjunto de métricas foi particularmente importante porque permitiu avaliar não apenas se o DPD calculava a resposta correta, mas também se o fazia de forma repetitiva, previsível e sustentável ao longo de campanhas longas de dados.

Sob a ótica epistemológica do capítulo, esse ponto é importante porque impede que a campanha seja reduzida a julgamentos qualitativos sobre gráficos. Cada teste teve critérios objetivos de sucesso ou fracasso. Em HW012, por exemplo, não bastava que a curva “parecesse boa”: era necessário que não houvesse overflow indevido, que a monotonicidade permanecesse preservada e que a resposta não apresentasse saturações espúrias. Em HW019 e HW020, por outro lado, a simples ausência de overflow não era suficiente, pois a perda de monotonicidade já era tratada como evidência de degradação funcional relevante. Em HW024, finalmente, a reprodutibilidade foi julgada por um conjunto de métricas convergentes, e não por um único indicador isolado.

Essa maneira de estruturar os critérios de aprovação fortalece a qualidade científica da campanha por duas razões. Primeiro, porque reduz subjetividade na interpretação dos resultados. Segundo, porque torna cada conclusão auditável: a partir dos CSVs e das figuras, um leitor externo pode verificar quais foram os limites usados para aceitar ou rejeitar determinado comportamento. Em um trabalho de engenharia, essa rastreabilidade é fundamental para distinguir uma demonstração experimental sólida de uma simples ilustração de bancada.

Tabela 7.2 - Critérios gerais de aprovação empregados na campanha de hardware

| Classe de ensaio | Indicadores principais de aprovação | Indícios típicos de reprovação |
| --- | --- | --- |
| Comunicação e bring-up | Retorno correto de comandos, escrita/leitura íntegra, LEDs e flags coerentes | Timeout, bytes inválidos, memória inconsistente |
| Curvas AM/AM e AM/PM | Monotonicidade coerente, ausência de saturação espúria, resposta compatível com coeficientes | Saltos locais, overflow indevido, dispersão incompatível |
| Saturação e compressão | Transição fisicamente interpretável, ponto de compressão identificável, limites numéricos coerentes | Saturação prematura, recortes indevidos, máximos locais anômalos |
| Sensibilidade paramétrica | Ordenamento consistente entre curvas, deslocamentos compatíveis com o parâmetro variado | Inversões de perfil, respostas desorganizadas, perda de previsibilidade |
| Temporal e dinâmico | Latência fixa, jitter nulo, throughput estável, checkpoints coerentes | Variação de latência, perdas, duplicações, reordenação |
| Reprodutibilidade estatística | Repetição das métricas-chave e baixa dispersão relativa entre runs | Degradação de fluxo, deriva temporal, divergências funcionais sistemáticas |

## 7.5 Ensaios de bring-up e infraestrutura: HW001 a HW011

Os testes HW001 a HW011 exerceram papel essencial no amadurecimento do ambiente experimental. Embora esses ensaios não tenham sido concebidos para a caracterização fina da curva de predistorção, eles estabeleceram a infraestrutura que tornou viáveis os demais experimentos. Em termos práticos, esse conjunto validou o enlace UART entre o computador e a FPGA, a integridade do protocolo de troca de comandos, o funcionamento dos sinais de `BUSY`, `DONE` e `ERROR`, além da leitura e escrita de memórias e registradores auxiliares.

Essa etapa foi particularmente importante porque o ambiente de bancada sofreu ajustes físicos ao longo do desenvolvimento, incluindo reorganização da lógica de acionamento dos LEDs de estado e padronização dos top-levels de teste para a nova convenção elétrica adotada na placa experimental. A consolidação desses testes reduziu o risco de que falhas de integração entre host e FPGA fossem interpretadas incorretamente como falhas do algoritmo de predistorção.

Do ponto de vista editorial, os testes HW001 a HW011 podem ser compreendidos como a camada de confiabilidade da plataforma experimental. Sua principal contribuição para este capítulo é demonstrar que o DPDnano-Lite não foi avaliado em condições improvisadas, mas sim sobre uma infraestrutura previamente estabilizada e validada. Isso aumenta a credibilidade dos resultados posteriores e reforça a rastreabilidade da campanha de hardware.

Mesmo não sendo o foco central da análise não linear, esses ensaios merecem registro mais explícito porque sua ausência comprometeria a legitimidade de todo o restante do capítulo. O HW001, por exemplo, confirmou a comunicação básica por UART e a capacidade de resposta ao comando mínimo de presença do sistema. HW002 e HW003 estenderam essa confiança para operações de memória e controle elementar. Na sequência, HW004 a HW008 consolidaram a infraestrutura de leitura, escrita, status e instrumentação de apoio. Por fim, HW009 a HW011 aproximaram o ambiente de teste do núcleo DPD propriamente dito, validando top-levels e rotinas já voltadas ao fluxo de dados do predistorcedor.

Essa progressão deve ser entendida como parte da validade interna da campanha. Em outras palavras, antes de concluir qualquer coisa sobre compressão, rotação de fase ou reprodutibilidade, foi necessário demonstrar que o canal de observação entre host e FPGA não estava corrompendo a evidência experimental. Ao registrar esse bloco de forma conjunta, o capítulo mostra que os resultados posteriores não emergiram de uma bancada instável, mas de um ambiente de ensaio amadurecido ao longo de sucessivos testes de infraestrutura.

## 7.6 Caracterização AM/AM e influência da frequência: HW012

O ensaio HW012 foi o primeiro experimento em que o núcleo DPD passou a ser avaliado como objeto central, e não apenas como parte da infraestrutura de teste. Seu propósito foi levantar a curva AM/AM diretamente em FPGA, isto é, medir a magnitude de saída em função da magnitude de entrada, sob diferentes combinações de coeficientes e diferentes frequências internas de operação. Em termos de interpretação física, o teste procurou verificar se a implementação fixa em Q1.15 preservava, no hardware real, a curvatura imposta pela combinação entre termo linear e termo cúbico do modelo polinomial reduzido adotado no projeto (DING et al., 2004; MORGAN et al., 2006).

Esse ensaio assumiu papel estratégico na campanha porque foi nele que a meta inicial de operação em aproximadamente 100 MHz começou a ser confrontada por evidência experimental concreta. Em um primeiro momento, a expectativa era que a arquitetura pudesse operar nessa faixa com base em tentativas de fechamento de síntese e em alterações locais de pipeline. Contudo, quando o teste passou a ser repetido em FPGA real com varredura extensa de amplitude, surgiram sintomas incompatíveis com o comportamento físico esperado do predistorcedor: pontos isolados de saturação em amplitudes nas quais o modelo deveria permanecer em regime contínuo, quebras abruptas de monotonicidade, ganhos aparentes maiores que o previsto e dispersões entre amostras adjacentes que não podiam ser atribuídas apenas ao efeito do termo cúbico.

Do ponto de vista metodológico, o valor do HW012 está justamente em separar duas noções que, em projetos digitais, nem sempre coincidem: a possibilidade de sintetizar um circuito e a capacidade de validá-lo experimentalmente com coerência funcional. O fato de o sistema compilar em frequências mais altas não significou, automaticamente, que a operação física estivesse confiável. A curva medida revelou que a elevação do clock interno reduzia a margem de temporização do caminho de dados a ponto de introduzir anomalias observáveis na própria resposta AM/AM, o que é um indício mais grave do que um simples alerta de ferramenta, pois afeta diretamente o significado experimental do resultado (BHASKER; CHADHA, 2009).

À medida que a frequência foi reduzida, o comportamento do sistema tornou-se progressivamente mais coerente. Em torno de 75 MHz e acima, ainda se observavam eventos esporádicos de overflow, saturações indevidas ou falhas de monotonicidade em regiões de amplitude que deveriam permanecer suaves. Na faixa intermediária entre 65 MHz e 70 MHz, houve melhora parcial, mas ainda não suficientemente robusta para sustentar uma campanha científica final. Somente ao atingir 60 MHz o predistorcedor passou a exibir, de forma repetitiva, a curva esperada para os coeficientes adotados, sem saltos espúrios, sem inversões locais indevidas e sem sintomas de instabilidade estrutural.

[[FIGURE:hw012_dpd_am_am_vr02.png|Figura 7.1 - Curva AM/AM obtida no ensaio HW012, utilizada como referência para a validação da operação estável do DPDnano-Lite em 60 MHz.]]

A Figura 7.1 é, portanto, mais do que uma curva ilustrativa: ela constitui a evidência experimental que sustentou o congelamento da campanha em 60 MHz. Nessa condição, a resposta se mostrou suave, monotônica e compatível com a interpretação do modelo implementado. Para os coeficientes utilizados na versão de referência do teste, a saída cresceu de forma estável até a região de maior amplitude sem disparos artificiais de saturação. Isso permitiu afirmar que o comportamento observado passou a refletir o modelo arquitetural do DPDnano-Lite, e não mais efeitos parasitas da temporização.

Outro ponto importante do HW012 foi a comparação indireta entre o núcleo congelado `rtl_v3_1` e tentativas posteriores de refinamento em uma trilha `rtl_v3_2`. Foram estudadas alterações em blocos como `poly_branch`, `poly_kernel`, `rounding` e `saturator`, além de experimentos com redistribuição de pipeline. Em alguns casos, houve melhora pontual de Fmax teórica; em outros, o ganho foi apenas marginal; e, em diversos cenários, a melhora de síntese não se traduziu em melhora real das curvas de hardware. Esse contraste reforça uma conclusão importante para o trabalho: no contexto da FPGA adotada, o mérito de uma alteração arquitetural não pode ser julgado apenas por MHz teóricos, mas pela manutenção simultânea de corretude funcional, previsibilidade da curva e repetibilidade experimental.

Assim, o HW012 consolidou três conclusões centrais. A primeira é que o DPDnano-Lite implementa corretamente a resposta AM/AM proposta quando executado dentro da sua faixa segura de temporização. A segunda é que a meta inicial de 100 MHz não foi confirmada experimentalmente, apesar dos esforços de ajuste arquitetural. A terceira é que o núcleo `rtl_v3_1`, operando a 60 MHz, representou a melhor solução de compromisso entre simplicidade, coerência física da curva e reprodutibilidade dos testes, tornando-se a base definitiva para os ensaios subsequentes.

Tabela 7.3 - Síntese da campanha de frequência e refinamento arquitetural observada no HW012

| Condição investigada | Situação experimental | Interpretação |
| --- | --- | --- |
| `rtl_v3_1` em 60 MHz | Curvas estáveis, sem overflow espúrio, sem perda de monotonicidade | Condição robusta e repetível |
| `rtl_v3_1` em 63-64,125 MHz | Em combinações específicas de coeficientes, ainda se observou estabilidade | Faixa limítrofe, porém ainda defensável em casos controlados |
| `rtl_v3_1` acima de 64,125 MHz | Surgem overflow, saturações indevidas e anomalias locais | Faixa não consolidada como segura |
| `rtl_v3_2` com pipelining adicional | Melhoras pontuais de Fmax teórica, mas persistência de falhas em hardware | Ganho teórico sem validação funcional equivalente |
| Faixa próxima de 100 MHz | Curvas inconsistentes e resposta experimental pouco confiável | Meta não validada no hardware real |

Além de seu papel técnico, o HW012 teve também um papel metodológico dentro do TCC: ele impediu que o trabalho fosse conduzido por um viés de confirmação. Havia motivação clara para reportar frequências mais altas, mas os dados experimentais mostraram que isso não seria intelectualmente honesto. O valor científico do ensaio está, justamente, em permitir que a conclusão sobre 60 MHz seja apresentada como resultado de investigação, e não como escolha arbitrária de conveniência.

## 7.7 Saturação, overflow e rotação complexa: HW013 a HW016

Após a estabilização do clock em 60 MHz, a campanha passou a investigar com mais rigor a fronteira entre o comportamento matemático ideal do predistorcedor e os limites impostos pela implementação em ponto fixo. Esse bloco de testes teve duas frentes complementares. A primeira tratou da saturação e do overflow, isto é, da capacidade do sistema de lidar com amplitudes elevadas sem perder rastreabilidade numérica. A segunda tratou do comportamento de fase, validando a parte complexa da arquitetura e a possibilidade de reproduzir perfis AM/PM controlados.

O HW013 foi desenhado para empurrar a arquitetura até seus limites numéricos. Nesse ensaio, os coeficientes foram escolhidos de forma a aumentar progressivamente a magnitude de saída e observar em que ponto a representação Q1.15 deixava de comportar o valor calculado sem recorte. A relevância desse teste está em distinguir dois fenômenos aparentados, mas não equivalentes: compressão natural da curva não linear e saturação rígida imposta pelo formato numérico. A curva obtida mostrou que o DPDnano-Lite mantém tendência coerente com o modelo até a aproximação dos limites positivos e negativos, momento em que a resposta passa a ser truncada pelo intervalo representável.

[[FIGURE:hw013_dpd_saturation_overflow.png|Figura 7.2 - Curva de saturação e overflow observada no ensaio HW013, evidenciando o limite numérico da representação Q1.15.]]

Do ponto de vista científico, o HW013 é importante porque demonstra que a arquitetura não “falha silenciosamente” ao atingir o limite dinâmico: a curva revela explicitamente a transição para a região saturada. Isso dá previsibilidade à interpretação experimental e mostra que o comportamento fora da faixa linearizável pode ser identificado e delimitado com clareza. Além disso, o teste fornece uma ponte conceitual entre a teoria do modelo polinomial e a realidade de hardware, em que a largura de palavra passa a integrar a definição prática da faixa útil de operação.

Nos ensaios HW014 e HW015, o foco mudou da magnitude para a fase. Essa mudança é particularmente relevante porque uma arquitetura de DPD baseada em processamento complexo não deve ser validada apenas por curvas AM/AM. Em aplicações reais de linearização, a capacidade de reproduzir desvios de fase dependentes da amplitude é parte essencial da representação de não linearidades de amplificadores, especialmente quando se pretende aproximar a resposta do modelo a assinaturas AM/PM observáveis na prática (ZHU, 2016; GILABERT; DING, 2024).

O HW014 validou a multiplicação complexa interna do núcleo. A estratégia foi aplicar coeficientes complexos controlados e observar se a saída apresentava rotação coerente em relação à entrada. O ensaio foi analisado sob duas perspectivas complementares: a curva média de desvio de fase em função da magnitude e a representação geométrica das amostras no plano I/Q. A primeira confirma quantitativamente o desvio angular; a segunda fornece evidência visual de que a rotação não é um artefato de cálculo isolado, mas um efeito consistente no espaço complexo.

[[FIGURE:hw014_dpd_am_pm.png|Figura 7.3 - Desvio de fase médio em função da magnitude no ensaio HW014, validando a multiplicação complexa da arquitetura.]]

[[FIGURE:hw014_dpd_iq_plane.png|Figura 7.4 - Representação das amostras de entrada e saída no plano I/Q no ensaio HW014, evidenciando a rotação complexa induzida pelos coeficientes.]]

O valor técnico do HW014 está em demonstrar que a implementação do termo complexo não apenas existe do ponto de vista RTL, mas produz um deslocamento angular observável, estável e compatível com a parametrização aplicada. Em outras palavras, o teste valida a integridade do caminho complexo completo: formação do produto, acumulação no núcleo, arredondamento e saída em ponto fixo. Isso é especialmente importante porque qualquer erro nesses estágios poderia aparecer como rotação inconsistente, espelhamento indevido ou assimetria entre quadrantes.

O HW015 aprofundou essa análise ao investigar explicitamente a dependência AM/PM em função da amplitude. Em vez de apenas provar que existe rotação, o ensaio procurou medir como essa rotação evolui à medida que a entrada aumenta. O resultado mostrou crescimento monotônico do desvio de fase, sem rupturas ou inversões indevidas, o que é compatível com a interpretação de que o termo cúbico imaginário passa a dominar progressivamente a resposta à medida que a amplitude cresce.

[[FIGURE:hw015_dpd_ampm.png|Figura 7.5 - Curva AM/PM dependente da amplitude observada no ensaio HW015.]]

Esse resultado é cientificamente relevante porque mostra que o DPDnano-Lite não reproduz apenas um deslocamento de fase constante, mas um efeito de fase dependente do nível do sinal, característica fundamental de modelos comportamentais de predistorção. Em uma leitura mais ampla, o teste confirma que a arquitetura preserva a relação entre módulo e fase mesmo sob representação simplificada, reforçando a adequação da especialização adotada no projeto.

O HW016 concluiu esse bloco reunindo quatro perfis distintos de AM/PM em uma única campanha. Essa escolha teve duas vantagens metodológicas. Primeiro, permitiu comparar diretamente perfis fraco, médio e forte de rotação mantendo o mesmo ambiente experimental. Segundo, serviu como teste de consistência relativa: não bastava que cada curva individual fosse plausível; era necessário que o ordenamento entre perfis fosse preservado.

[[FIGURE:hw016_dpd_ampm_comparison.png|Figura 7.6 - Comparação entre quatro perfis AM/PM medidos no ensaio HW016.]]

Os resultados mostraram que o sistema respondeu de forma organizada à variação dos coeficientes imaginários, produzindo famílias de curvas com separação coerente e comportamento monotônico compatível com a intensidade crescente do termo não linear. Sob a ótica de validação, isso amplia a confiança na arquitetura, pois indica que o núcleo responde a perturbações paramétricas de maneira estruturada e não caótica.

Em conjunto, os ensaios HW013 a HW016 mostram que a implementação em FPGA preserva três propriedades decisivas: o reconhecimento dos limites numéricos do formato Q1.15, a correta operação do caminho complexo e a capacidade de gerar perfis AM/PM controlados. Esse bloco, portanto, transforma a arquitetura de um simples gerador de deformação em módulo em um predistorcedor digital com comportamento complexo rastreável e experimentalmente verificável.

Há ainda uma implicação arquitetural importante nesse bloco. Ao validar fase e magnitude separadamente, os ensaios mostram que a simplificação do modelo não destruiu a expressividade mínima necessária para representar efeitos relevantes de não linearidade. Isso é particularmente significativo em uma proposta “Lite”, cujo valor depende justamente de preservar comportamento útil com custo estrutural reduzido. Em outras palavras, HW013 a HW016 ajudam a demonstrar que a economia arquitetural do DPDnano-Lite não eliminou os mecanismos essenciais de modelagem.

## 7.8 Compressão, ganho incremental e janela operacional: HW017 a HW021

Uma vez demonstradas a estabilidade em 60 MHz e a coerência dos mecanismos AM/PM, a campanha passou a estudar com maior profundidade a geometria da curva de transferência. O objetivo desse bloco foi responder a uma pergunta central para qualquer arquitetura de predistorção: em que região de amplitudes e coeficientes a resposta ainda pode ser considerada útil, previsível e interpretável como comportamento controlado do modelo, e em que momento ela passa a entrar em zonas de compressão severa, saturação ou não monotonicidade? Essa discussão é particularmente importante em uma arquitetura compacta, pois a redução de complexidade tende a estreitar a margem entre faixa útil e faixa problemática.

O HW017 foi o primeiro ensaio desse bloco e teve como foco a transição entre regimes. Em vez de procurar apenas o ponto de saturação, o teste observou a trajetória completa da curva em relação à reta ideal `y = x`, permitindo identificar a passagem por expansão inicial, compressão subsequente e posterior aproximação do limite de saturação. Esse comportamento é relevante porque traduz, em linguagem experimental, a ação combinada do termo linear e do termo cúbico sobre a forma da curva.

[[FIGURE:hw017_dpd_saturation_compression.png|Figura 7.7 - Curva de saturação e compressão do ensaio HW017, destacando a transição para regime fortemente não linear.]]

A principal contribuição do HW017 está em tornar visível que a arquitetura não opera apenas em dois estados simplificados, “linear” e “saturada”. Entre esses extremos existe uma faixa de curvatura progressiva na qual o ganho local começa a se alterar e a referência linear deixa de ser representativa. Para a redação científica do trabalho, esse ensaio é importante porque aproxima a análise do vocabulário clássico de amplificadores de potência, em que expansão, compressão e recorte constituem marcos distintos da resposta do sistema.

O HW018 refinou esse raciocínio ao focar explicitamente o ponto de compressão de 1 dB. Em vez de observar a curva de maneira puramente qualitativa, o ensaio definiu uma métrica objetiva capaz de resumir a faixa útil de operação em um valor diretamente interpretável. O ponto de compressão de 1 dB indica a amplitude a partir da qual a saída passa a se afastar da extrapolação de pequeno sinal de forma suficientemente intensa para ser tratada como compressão relevante.

[[FIGURE:hw018_dpd_compression_p1db.png|Figura 7.8 - Identificação do ponto de compressão de 1 dB no ensaio HW018.]]

Esse tipo de medida tem grande valor porque conecta a validação do DPDnano-Lite a um critério amplamente utilizado em caracterização de não linearidades. Em vez de afirmar genericamente que “a curva comprime”, o teste quantifica onde essa compressão passa a ter significado operacional. Para um projeto de FPGA com recursos limitados, essa informação é especialmente útil porque ajuda a delimitar a região na qual a arquitetura ainda responde de modo previsível antes que a distorção se torne dominante.

O HW019 introduziu uma métrica ainda mais sensível: o ganho incremental. Enquanto o ganho estático `OUT/IN` tende a suavizar detalhes locais, o ganho incremental `dOUT/dIN` expõe diretamente a inclinação instantânea da curva. Isso permitiu observar, com muito mais precisão, se a resposta permanecia monotônica e se a curvatura evoluía de forma suave ou entrava em regiões críticas.

[[FIGURE:hw019_dpd_compression_base.png|Figura 7.9 - Curva base de compressão AM/AM utilizada no ensaio HW019.]]

[[FIGURE:hw019_dpd_incremental_gain.png|Figura 7.10 - Ganho incremental obtido no ensaio HW019, evidenciando a evolução local da resposta diferencial.]]

Do ponto de vista analítico, o HW019 foi um dos testes mais ricos do capítulo porque permitiu discutir não monotonicidade com maior rigor. Uma curva AM/AM pode parecer aceitável em visão global e, ainda assim, esconder trechos em que a resposta diferencial se degrada. Quando o ganho incremental se aproxima de zero ou varia de forma irregular, a arquitetura entra em uma zona em que pequenas variações de entrada deixam de produzir resposta proporcional e previsível. Para um predistorcedor, isso é especialmente relevante, pois a efetividade do ajuste depende justamente de a curva ser controlável e ordenada. Em outras palavras, o ganho incremental funciona como um indicador fino da margem operacional da arquitetura.

O HW020 ampliou radicalmente a perspectiva ao abandonar a visão unidimensional de uma única curva e mapear o comportamento do sistema no plano bidimensional dos coeficientes. Esse ensaio produziu um conjunto de mapas que classificam regiões seguras, compressivas, expansivas, saturadas, com overflow e com não monotonicidade. A importância desse teste reside no fato de que ele transforma uma sequência de observações pontuais em uma cartografia experimental da janela operacional do DPDnano-Lite.

[[FIGURE:hw020_dpd_status_map.png|Figura 7.11 - Mapa de classificação da janela operacional no ensaio HW020.]]

[[FIGURE:hw020_dpd_peak_output_map.png|Figura 7.12 - Mapa do valor máximo de saída no ensaio HW020.]]

[[FIGURE:hw020_dpd_saturation_map.png|Figura 7.13 - Mapa da amplitude de entrada no início da saturação no ensaio HW020.]]

[[FIGURE:hw020_dpd_representative_curves.png|Figura 7.14 - Curvas representativas da janela operacional obtidas no ensaio HW020.]]

Com esses mapas, tornou-se possível formular uma discussão muito mais robusta sobre os limites da arquitetura. Em vez de dizer apenas que certos coeficientes “funcionam melhor” que outros, o trabalho passa a mostrar em que regiões do espaço paramétrico o núcleo se mantém previsível, em que regiões ele comprime de forma ainda útil, e em que regiões ele entra em comportamento inadequado para uma operação confiável. Esse tipo de resultado é particularmente valioso em TCC e em publicação técnica, porque fornece uma interpretação de projeto e não apenas uma coleção de curvas isoladas.

O HW021 fechou esse bloco com uma análise de sensibilidade paramétrica em torno da condição nominal. A ideia foi observar como pequenas variações em `coef1` e `coef3` deformam a curva de transferência, não apenas em valor absoluto, mas também em relação à resposta de referência. Isso permitiu distinguir o papel de cada parâmetro na construção da curva AM/AM.

[[FIGURE:hw021_dpd_coef1_amam.png|Figura 7.15 - Família de curvas AM/AM para variação de `coef1` no ensaio HW021.]]

[[FIGURE:hw021_dpd_coef1_delta.png|Figura 7.16 - Desvio em relação à curva nominal para variação de `coef1` no ensaio HW021.]]

[[FIGURE:hw021_dpd_coef3_amam.png|Figura 7.17 - Família de curvas AM/AM para variação de `coef3` no ensaio HW021.]]

[[FIGURE:hw021_dpd_coef3_delta.png|Figura 7.18 - Desvio em relação à curva nominal para variação de `coef3` no ensaio HW021.]]

Os resultados mostraram que `coef1` atua principalmente como regulador do ganho global e desloca a curva de forma mais uniforme, enquanto `coef3` afeta com mais intensidade a curvatura e a região de altas amplitudes. Essa distinção é muito importante do ponto de vista arquitetural, pois demonstra que os coeficientes não exercem papéis redundantes. Ao contrário, a separação entre contribuição linear e cúbica permanece visível na resposta em hardware, o que reforça a coerência entre o modelo matemático simplificado e a implementação física.

Tomados em conjunto, os ensaios HW017 a HW021 constroem uma leitura experimental madura da arquitetura. Eles mostram onde a compressão começa, como ela evolui localmente, em que regiões surgem indícios de não monotonicidade e quais deslocamentos paramétricos ainda mantêm o sistema em zona segura. Esse bloco é, portanto, fundamental para sustentar que o DPDnano-Lite não apenas “funciona”, mas possui uma janela operacional empiricamente delimitada e tecnicamente interpretável.

Esse bloco também é o principal responsável por transformar o capítulo em uma análise de projeto, e não apenas em relato de bancada. Ao longo de HW017 a HW021, a arquitetura deixa de ser observada apenas por respostas individuais e passa a ser entendida como sistema com fronteiras operacionais. Isso é essencial para um capítulo forte de TCC, porque permite discutir o núcleo em termos de engenharia: quais combinações são úteis, quais são arriscadas, quais levam a expansão excessiva, quais conduzem a compressão controlada e quais empurram a curva para uma região não monotônica.

Do ponto de vista prático, a não monotonicidade merece ênfase especial. Em várias arquiteturas digitais, o primeiro reflexo do limite de operação é o overflow. No DPDnano-Lite, os ensaios mostraram que existe um limitante anterior e mais sutil: a perda de ganho incremental positivo. Isso significa que o sistema pode continuar “rodando” sem saturar rigidamente, mas já ter perdido interpretabilidade física como curva de transferência progressiva. Esse achado enriquece bastante a discussão do capítulo porque mostra que o limite da arquitetura não é apenas numérico, mas também comportamental.

## 7.9 Estabilidade temporal, throughput e robustez dinâmica: HW022 a HW024

Os ensaios HW022 a HW024 encerram a campanha sob uma ótica diferente da adotada nas seções anteriores. Se HW012 a HW021 mostraram principalmente a forma da resposta do DPD, este bloco investiga o seu comportamento temporal e sistêmico. Essa distinção é importante porque, em um predistorcedor sintetizável, não basta produzir curvas coerentes para amostras isoladas; é necessário demonstrar também que a arquitetura mantém latência previsível, integridade de fluxo e repetibilidade quando submetida a tráfego prolongado e cenários dinâmicos.

O HW022 tratou especificamente da latência sob diferentes padrões de estímulo. O ensaio foi estruturado para verificar se a cadeia de processamento preservava o mesmo número de ciclos entre entrada e saída em cenários distintos de tráfego, incluindo rajadas e variações de ocupação. O resultado principal foi a confirmação de latência fixa de 6 ciclos e jitter nulo.

[[FIGURE:hw022_dpd_latency_by_scenario.png|Figura 7.19 - Latência média por cenário de tráfego no ensaio HW022.]]

[[FIGURE:hw022_dpd_timeline_burst.png|Figura 7.20 - Timeline de entrada e saída no cenário `burst` do ensaio HW022, evidenciando latência constante.]]

Esse achado é de grande importância para a defesa técnica da arquitetura, pois mostra que o pipeline do DPDnano-Lite se comporta como caminho temporalmente determinístico. Em aplicações digitais embarcadas, especialmente quando o bloco é parte de uma cadeia maior de processamento, a previsibilidade da latência é tão importante quanto a corretude funcional. Uma latência oscilante comprometeria a rastreabilidade dos testes, a correlação entre amostras e, em última instância, a utilizabilidade do sistema como bloco reconfigurável em processamento contínuo (BHASKER; CHADHA, 2009).

O HW023 aumentou significativamente a exigência experimental. Em vez de cenários de menor extensão, o ensaio operou com fluxo contínuo de até 1.000.000 de amostras, com cinco perfis dinâmicos de coeficientes e atualização periódica a cada 256 amostras. Esse teste foi particularmente importante porque aproximou o sistema de uma situação realista de operação prolongada, em que o núcleo não apenas processa muitas amostras, mas também precisa acomodar mudanças paramétricas ao longo da execução.

[[FIGURE:hw023_dpd_latency_stability.png|Figura 7.21 - Estabilidade da latência ao longo dos checkpoints do ensaio HW023.]]

[[FIGURE:hw023_dpd_instantaneous_throughput.png|Figura 7.22 - Throughput instantâneo por bloco de 100.000 amostras no ensaio HW023.]]

[[FIGURE:hw023_dpd_integrity_checkpoints.png|Figura 7.23 - Integridade dos checkpoints de processamento no ensaio HW023.]]

Os resultados do HW023 mostraram throughput efetivo de aproximadamente 60 MS/s, latência estável de 6 ciclos, checkpoints coerentes e ausência de perdas, duplicações ou reordenação. Cientificamente, isso significa que o DPDnano-Lite não apenas calcula corretamente sua resposta em pontos isolados, mas sustenta processamento contínuo sem degradar a integridade do fluxo. O uso de checkpoints ao longo da execução foi especialmente útil porque permitiu inspecionar o sistema sem depender apenas de uma métrica agregada final; assim, ficou demonstrado que a estabilidade temporal se mantém ao longo de toda a trajetória de processamento, e não apenas no início ou no fim da campanha.

O HW024 foi concebido como teste de reprodutibilidade estatística, isto é, uma validação da consistência do sistema ao repetir várias vezes o mesmo experimento em condições equivalentes. Foram realizadas dez execuções independentes de 1.000.000 de amostras cada, totalizando 10.000.000 de amostras processadas. Em todas elas, a latência permaneceu em 6 ciclos, o jitter foi nulo, o throughput ficou fixo em aproximadamente 59,999400 MS/s e não foram observadas perdas, duplicações, reordenação ou erros de fila.

[[FIGURE:hw024_dpd_latency_by_run.png|Figura 7.24 - Latência média por execução na campanha estatística do ensaio HW024.]]

[[FIGURE:hw024_dpd_throughput_by_run.png|Figura 7.25 - Throughput por execução na campanha estatística do ensaio HW024.]]

[[FIGURE:hw024_dpd_overflow_by_run.png|Figura 7.26 - Variação dos eventos de overflow entre execuções do ensaio HW024.]]

[[FIGURE:hw024_dpd_results_by_run.png|Figura 7.27 - Resultado consolidado das execuções do ensaio HW024.]]

Um aspecto que exigiu interpretação cuidadosa nesse teste foi a variação da assinatura agregada de saída entre execuções. Se analisada superficialmente, essa diferença poderia sugerir instabilidade funcional. Entretanto, a inspeção conjunta dos CSVs mostrou que os checkpoints principais permaneceram idênticos, a integridade de fluxo foi preservada, a latência não variou e o throughput permaneceu rigorosamente constante. Em outras palavras, a divergência observada na assinatura agregada não se manifestou como erro funcional mensurável ao nível do processamento e, por isso, não invalidou o ensaio. A decisão de enquadrar o HW024 como `PASS` baseou-se justamente em critérios mais robustos do que uma única assinatura final agregada.

Esse ponto merece destaque porque revela maturidade metodológica da campanha. Em vez de adotar um critério simplista e potencialmente enganoso, a validação foi sustentada por múltiplos indicadores convergentes: comportamento temporal, coerência entre checkpoints, ausência de falhas de transporte de dados e repetição do desempenho global. Isso torna a conclusão do HW024 muito mais defensável do ponto de vista científico.

Em conjunto, HW022, HW023 e HW024 demonstram que o DPDnano-Lite, na configuração final congelada, não é apenas funcionalmente correto, mas temporalmente previsível e operacionalmente robusto. Esse bloco é decisivo porque transforma a discussão da arquitetura em evidência de sistema: o núcleo funciona, mantém latência fixa, sustenta fluxo contínuo e repete seu comportamento ao longo de campanhas extensas em hardware real.

Vale destacar que esse bloco final funciona como uma espécie de prova de maturidade do trabalho. Até HW021, a campanha havia demonstrado que a arquitetura produzia respostas coerentes. A partir de HW022, a pergunta deixa de ser apenas “o núcleo calcula o que deveria?” e passa a ser “o núcleo consegue sustentar esse comportamento como bloco digital real, por muito tempo, sob fluxo contínuo e repetição?”. O fato de a resposta ter sido positiva em 60 MHz fortalece de modo decisivo a defesa do projeto.

## 7.10 Discussão sobre a frequência máxima validada

Um dos resultados mais relevantes deste capítulo, e possivelmente de todo o trabalho experimental, é a delimitação objetiva da frequência máxima validada para o DPDnano-Lite. Ao longo do desenvolvimento, houve esforço explícito para aproximar o núcleo da faixa de 100 MHz, objetivo natural quando se busca aumentar throughput e demonstrar competitividade arquitetural. No entanto, a campanha mostrou que, na FPGA escolhida e com a estrutura efetivamente implementada, a frequência de operação não pode ser avaliada apenas sob a ótica do fechamento lógico ou de estimativas de Fmax.

Os ensaios de HW012 em diante deixaram claro que a elevação do clock começou a se refletir diretamente na resposta funcional do sistema. Em vez de apenas reduzir margem de segurança interna, a aproximação de 100 MHz passou a produzir sintomas externos observáveis: saturações espúrias em pontos indevidos, irregularidades locais na curva AM/AM, falhas de monotonicidade, oscilações em métricas derivadas e redução da confiabilidade dos ensaios mais sensíveis. Em termos experimentais, isso significa que a frequência excessiva começou a “aparecer” na própria física do resultado medido, o que é muito mais crítico do que um simples alerta de temporização.

Esse diagnóstico foi reforçado pela sequência de tentativas de otimização arquitetural realizadas ao longo da campanha. Foram avaliadas redistribuições de pipeline e modificações em módulos como `poly_branch`, `poly_kernel`, `rounding` e `saturator`, buscando melhorar o caminho crítico e ampliar a faixa de operação. Ainda que algumas dessas alterações tenham produzido incrementos parciais de Fmax teórica, elas não geraram benefício sólido e repetível na operação prática. Em vários cenários, a resposta em hardware continuou apresentando problemas acima da condição final congelada, e em outros a melhora de síntese veio acompanhada de aumento de área e maior complexidade estrutural, sem retorno experimental equivalente.

Esse resultado é tecnicamente relevante porque afasta uma leitura ingênua de desempenho baseada apenas em números nominais. Em arquiteturas de Predistorção Digital para FPGA compacta, o mérito de uma solução não está simplesmente em “rodar mais rápido”, mas em manter simultaneamente coerência funcional, previsibilidade temporal e repetibilidade estatística (LI; MONTORO; GILABERT, 2024; SIPEED, 2026). A campanha do DPDnano-Lite mostrou que esse tripé deixou de ser satisfeito quando a frequência se aproximou de 100 MHz.

Por outro lado, a consolidação em 60 MHz apresentou um quadro experimental completamente distinto. Foi nessa frequência que o sistema conseguiu reunir, ao mesmo tempo, curvas AM/AM e AM/PM coerentes, ausência de anomalias espúrias relevantes, latência fixa de 6 ciclos, throughput estável próximo a 60 MS/s, integridade de fluxo preservada e reprodutibilidade estatística em campanhas longas. Portanto, a escolha final de 60 MHz não deve ser interpretada como concessão arbitrária, mas como conclusão sustentada por evidência empírica repetida ao longo de vários ensaios independentes.

Há ainda um aspecto conceitual importante. Em projetos acadêmicos e industriais, muitas vezes existe a tentação de reportar a maior frequência que “compila” ou que “parece fechar” em síntese. A estratégia adotada neste trabalho foi mais rigorosa: a frequência validada só foi aceita quando a operação completa do sistema se mostrou consistente em todos os planos relevantes de avaliação. Isso torna a conclusão mais honesta e também mais útil, pois oferece ao leitor não apenas um número de clock, mas uma faixa real de operação confiável.

Esse ponto deve ser entendido como uma contribuição metodológica do capítulo. Ao insistir em confrontar o fechamento temporal com curvas AM/AM, AM/PM, métricas dinâmicas e repetição estatística, a campanha mostrou que a engenharia de validação não pode ser reduzida à síntese. Em FPGAs compactas, especialmente quando o processamento envolve produtos complexos, arredondamento, saturação e alinhamentos internos de pipeline, a distância entre “sintetizável” e “experimentalmente confiável” pode ser grande. O capítulo 7 torna essa distância visível e quantificável.

| Frequência investigada | Situação observada | Conclusão experimental |
| --- | --- | --- |
| Próxima de 100 MHz | Curvas com inconsistências, overflow espúrio e perda de confiabilidade em ensaios sensíveis | Não validada como frequência operacional estável |
| Faixa intermediária acima de 60 MHz | Melhorias parciais, mas ainda com falhas ou dispersões incompatíveis com a campanha final | Não consolidada como condição segura |
| 60 MHz | Curvas consistentes, latência fixa, throughput estável e ausência de falhas de fluxo | Maior frequência validada sem erros na campanha final |

## 7.11 Síntese dos resultados

Os resultados obtidos ao longo da campanha permitem afirmar que o DPDnano-Lite atingiu o objetivo central deste trabalho: demonstrar a viabilidade de uma arquitetura de Predistorção Digital compacta, baseada em formulação polinomial especializada, implementável em FPGA com recursos limitados e validável experimentalmente com rastreabilidade técnica.

Sob a ótica funcional, o conjunto de ensaios mostrou que a arquitetura reproduziu de forma coerente os efeitos esperados de ganho linear, contribuição cúbica, saturação, compressão e rotação de fase. Mais do que isso, a campanha mostrou que esses efeitos não foram observados como fenômenos isolados, mas como parte de uma resposta organizada e interpretável: há uma curva AM/AM identificável, há perfis AM/PM consistentes, há fronteiras reconhecíveis entre regime útil e saturação, e há regiões paramétricas em que a resposta deixa de ser desejável por causa de compressão excessiva ou não monotonicidade.

Sob a ótica paramétrica, o capítulo mostrou que a arquitetura possui uma janela operacional empiricamente delimitada. Os ensaios de ganho incremental, mapas de coeficientes e sensibilidade mostraram que `coef1` e `coef3` exercem papéis distintos e previsíveis sobre a curva, e que a configuração do núcleo não pode ser tratada de forma arbitrária sem risco de empurrar o sistema para zonas de comportamento degradado. Esse resultado é particularmente importante porque adiciona densidade científica ao trabalho: em vez de apresentar apenas “um caso que funcionou”, o capítulo descreve como a arquitetura se comporta em torno da condição nominal e quais são os seus limites de ajuste.

Sob a ótica temporal, a campanha validou latência fixa de 6 ciclos e throughput de aproximadamente 60 MS/s na configuração final. Os testes HW022 a HW024 provaram que esse comportamento não foi eventual, mas repetitivo e sustentado ao longo de execuções extensas, com checkpoints coerentes, ausência de perdas e reprodutibilidade estatística global. Isso confere ao DPDnano-Lite não apenas corretude local, mas maturidade como sistema digital embarcado.

Talvez o resultado mais importante, porém, seja a combinação entre viabilidade e limite. O capítulo não apenas demonstra que a arquitetura funciona; ele também mostra onde ela deixa de ser experimentalmente confiável. A tentativa de alcançar 100 MHz, embora tecnicamente motivada, revelou-se incompatível com a consistência exigida para a campanha final. A escolha por 60 MHz, nesse contexto, transforma-se em conclusão científica e não em simples decisão prática. Em trabalhos de engenharia, essa explicitação dos limites é tão valiosa quanto a demonstração do sucesso, porque define com honestidade a faixa real em que a solução proposta pode ser defendida.

Sob a perspectiva de contribuição do TCC, esse resultado tem peso particular. O trabalho não termina apenas com a afirmação de que “foi possível implementar um DPD em FPGA pequena”, mas com uma delimitação muito mais útil: foi possível implementá-lo, caracterizá-lo extensivamente em hardware real, demonstrar seu comportamento em magnitude e fase, mapear sua janela operacional e identificar a frequência máxima em que ele se manteve estável sem comprometer a integridade experimental. Essa formulação é mais forte, mais científica e mais defensável do que uma simples enumeração de passes em testes.

## 7.12 Limitações experimentais e implicações para continuidade

Embora a campanha tenha sido suficiente para validar o DPDnano-Lite como arquitetura funcional em hardware real, alguns limites observados ao longo do capítulo merecem ser explicitados. O primeiro deles é o próprio teto experimental de frequência. Ainda que o projeto tenha sido explorado com ambição de 100 MHz e que versões experimentais do RTL tenham buscado maior profundidade de pipeline, o conjunto final de evidências mostrou que a operação confiável se concentrou em 60 MHz. Esse limite não invalida a proposta; ao contrário, define com honestidade a faixa em que ela foi realmente comprovada.

O segundo limite diz respeito à sensibilidade da arquitetura a regiões paramétricas mais agressivas. Os ensaios HW019 e HW020 mostraram que, para certos coeficientes, a resposta deixa de ser apenas comprimida e passa a perder monotonicidade. Esse comportamento é relevante porque indica que a flexibilidade paramétrica do núcleo não é irrestrita. Em outras palavras, a arquitetura é configurável, mas essa configurabilidade precisa ser exercida dentro de uma janela de coeficientes compatível com resposta fisicamente interpretável.

O terceiro limite está associado à própria natureza da validação realizada neste capítulo. A campanha foi muito forte na caracterização estrutural, temporal e comportamental em FPGA real, mas não teve como objetivo principal a avaliação de métricas clássicas de sistema de RF, como ACPR ou EVM em cadeia completa com amplificador físico. Portanto, o capítulo valida o predistorcedor como núcleo digital e como arquitetura sintetizável, mas ainda deixa espaço para investigações futuras que integrem o DPDnano-Lite a uma bancada RF completa.

Esses limites, entretanto, não reduzem a relevância do capítulo. Pelo contrário, eles qualificam suas conclusões. Ao explicitar onde a arquitetura é robusta, onde ela começa a degradar e quais aspectos permanecem como espaço de evolução, o texto ganha densidade científica e evita qualquer aparência de sobreafirmação. Essa postura é particularmente importante em um TCC de engenharia, no qual o mérito está tanto na demonstração de viabilidade quanto na clareza sobre os contornos da solução obtida.

## 7.13 Considerações finais do capítulo

Este capítulo apresentou a validação em hardware do DPDnano-Lite por meio da bateria de ensaios HW001 a HW024. O conjunto dos resultados mostrou que a solução proposta atingiu maturidade experimental suficiente para sustentar a arquitetura congelada em `rtl_v3_1` operando a 60 MHz como configuração final validada.

Além de confirmar o comportamento funcional do predistorcedor, a campanha em FPGA real demonstrou que a proposta é tecnicamente defensável sob a ótica de arquitetura digital, temporização e reprodutibilidade experimental. Dessa forma, os resultados aqui obtidos fornecem a base concreta para as conclusões gerais do trabalho e para a discussão final sobre as contribuições e limitações do DPDnano-Lite.
