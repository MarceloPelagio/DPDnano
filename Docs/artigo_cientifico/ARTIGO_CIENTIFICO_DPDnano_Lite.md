# DPDnano-Lite: Arquitetura RTL Compacta de Predistorção Digital em Ponto Fixo para FPGA de Pequeno Porte

**Autores:** [Nome do Integrante 1], [Nome do Integrante 2], [Nome do Integrante 3]  
**Instituição:** [Nome da Instituição]  
**Curso:** [Nome do Curso]  
**E-mail:** [e-mails dos autores]  

## Resumo

Este artigo apresenta o DPDnano-Lite, uma arquitetura RTL compacta para predistorção digital (Digital Predistortion, DPD) voltada a FPGA de pequeno porte. A proposta foi concebida para materializar, em Verilog-2001 sintetizável, um predistorcedor polinomial complexo de baixa ordem com custo estrutural reduzido, preservando previsibilidade temporal, disciplina numérica e modularidade de implementação. A arquitetura congelada utiliza entrada complexa em Q1.15, ramo linear por multiplicação complexa, ramo cúbico de terceira ordem, acumulação registrada em largura estendida, arredondamento aritmético, conversão controlada de escala e saturação final. O trabalho foi direcionado à plataforma Tang Nano 4K, baseada no dispositivo Gowin GW1NSR-LV4C, mas preserva portabilidade dentro de fluxos RTL convencionais. A validação experimental foi organizada em duas frentes: testes funcionais TC001 a TC010 e ensaios de caracterização TMQ001 a TMQ013. Os resultados mostram latência fixa de cinco ciclos, vazão de uma amostra válida por ciclo após enchimento do pipeline, entrega integral de vetores em campanhas extensas, erro máximo de quantização inferior a 0,5 LSB no ensaio dedicado, erro RMS de magnitude inferior a 0,007% em cenário complexo e repetibilidade bit a bit mesmo sob estresse com saturação frequente. Em conjunto, os resultados indicam que o DPDnano-Lite constitui uma solução coerente para estudos e implementações de DPD em hardware reconfigurável com recursos restritos, oferecendo uma base sólida para evoluções futuras com memória explícita, ordens polinomiais superiores e adaptação de coeficientes.

**Palavras-chave:** predistorção digital, FPGA, ponto fixo, Verilog, DPD, arquitetura RTL.

## Abstract

This paper presents DPDnano-Lite, a compact RTL architecture for Digital Predistortion (DPD) targeting small FPGA devices. The design materializes a low-order complex polynomial predistorter in synthesizable Verilog-2001 while preserving temporal predictability, numerical discipline, and modular implementation. The frozen architecture uses Q1.15 complex input, a linear branch based on complex multiplication, a third-order nonlinear branch, registered accumulation with extended word length, arithmetic rounding, controlled scale conversion, and final saturation. The implementation was guided by the Tang Nano 4K platform, based on the Gowin GW1NSR-LV4C device, while remaining portable to standard RTL flows. Experimental validation was organized into two complementary fronts: functional tests TC001 to TC010 and characterization campaigns TMQ001 to TMQ013. Results show fixed five-cycle latency, one valid sample per cycle after pipeline fill, full vector delivery in long campaigns, maximum quantization error below 0.5 LSB in the dedicated experiment, magnitude RMS error below 0.007% in a complex scenario, and bit-exact repeatability even under severe saturation stress. Taken together, the results indicate that DPDnano-Lite is a technically consistent solution for DPD studies and implementations on resource-constrained reconfigurable hardware, while also providing a solid base for future extensions including explicit memory, higher polynomial orders, and adaptive coefficients.

**Keywords:** digital predistortion, FPGA, fixed-point, Verilog, RTL architecture.

## 1. Introdução

Amplificadores de potência empregados em transmissores de radiofrequência operam sob uma tensão clássica entre linearidade e eficiência. À medida que se busca maior eficiência energética, cresce a probabilidade de operação em regiões nas quais os efeitos não lineares se tornam mais pronunciados, produzindo distorção na envoltória, expansão espectral e degradação da qualidade do sinal transmitido. Nesse contexto, a predistorção digital consolidou-se como uma das estratégias mais relevantes para compensação de não linearidades em cadeias de transmissão modernas (GILABERT; DING, 2024; ZHU, 2016; DING et al., 2004).

Apesar da maturidade conceitual da DPD na literatura, sua implementação em hardware continua exigindo escolhas arquiteturais cuidadosas. Soluções com alta expressividade algorítmica podem tornar-se estruturalmente pesadas, principalmente quando incluem memória explícita, múltiplos ramos polinomiais e adaptação online de coeficientes. Essa dificuldade se intensifica quando o alvo não é uma FPGA de grande porte, mas sim uma plataforma compacta, na qual área, blocos DSP, registradores e margem de integração são recursos finitos e críticos (LI; MONTORO; GILABERT, 2024).

Foi nesse espaço de projeto que surgiu o DPDnano-Lite. Em vez de partir de uma formulação maximalista e reduzi-la posteriormente, a proposta foi concebida desde o início como uma arquitetura enxuta, verificável e implementável em FPGA pequena. O objetivo central não foi competir com arquiteturas amplas de DPD em capacidade algorítmica, mas demonstrar que um predistorcedor digital tecnicamente coerente pode ser construído em RTL com disciplina numérica, comportamento temporal previsível e custo compatível com dispositivos reconfiguráveis modestos.

Neste trabalho, a arquitetura adotada corresponde a um predistorcedor polinomial complexo de baixa ordem, especializado em um ramo linear e um ramo cúbico aplicados à amostra corrente. Essa escolha preserva o núcleo funcional da DPD polinomial, ao mesmo tempo em que reduz drasticamente a complexidade estrutural. A implementação foi realizada em Verilog-2001, com aritmética integralmente em ponto fixo e organização pipeline de latência determinística (DING et al., 2004; MORGAN et al., 2006).

Do ponto de vista científico, a contribuição do trabalho não se limita à descrição do código RTL. O DPDnano-Lite foi submetido a uma campanha experimental abrangente, composta por testes funcionais direcionados e por ensaios de caracterização numérica, temporal, estatística e operacional. Com isso, o artigo não apenas apresenta uma arquitetura, mas também documenta de forma rastreável como essa arquitetura se comporta sob diferentes condições de excitação.

Assim, o objetivo deste artigo é apresentar a formulação, a implementação e a validação do DPDnano-Lite, destacando seus compromissos arquiteturais, sua política numérica e os principais resultados observados em simulação.

## 2. Fundamentação e motivação da proposta

Modelos polinomiais ocupam posição central na literatura de predistorção digital por oferecerem boa relação entre expressividade e custo computacional. Trabalhos clássicos mostraram que estruturas baseadas em polinômios com memória podem capturar de forma robusta a resposta não linear de amplificadores de potência, enquanto formulações generalizadas ampliam essa capacidade ao custo de maior complexidade estrutural. Em paralelo, estudos recentes sobre implementação em hardware reforçam que a escolha do modelo não pode ser dissociada do orçamento computacional disponível (DING et al., 2004; MORGAN et al., 2006; LI; MONTORO; GILABERT, 2024).

No caso do DPDnano-Lite, o problema de projeto foi deliberadamente formulado sob restrição. A arquitetura deveria:

1. Ser sintetizável em Verilog-2001.
2. Operar integralmente em ponto fixo.
3. Permanecer modular e verificável.
4. Ser compatível com FPGA de pequeno porte.
5. Preservar significado técnico como predistorcedor polinomial complexo real.

Essas exigências tornam pouco adequado adotar, já na primeira versão validada, uma estrutura de memória explícita ou alta ordem polinomial. Em vez disso, a proposta Lite recorta a parcela essencial do fenômeno a ser modelado: um ramo linear, responsável pela contribuição proporcional ao sinal, e um ramo cúbico, responsável pela principal componente não linear de terceira ordem.

Essa decisão não deve ser lida como simplificação arbitrária, mas como especialização consciente da arquitetura. O DPDnano-Lite não pretende esgotar a literatura de modelos comportamentais de DPD; ele pretende estabelecer uma base de hardware compacta, disciplinada e passível de expansão futura. Esse recorte é particularmente adequado quando o interesse é transformar teoria em um núcleo sintetizável, mensurável e auditável em ambiente acadêmico de engenharia.

## 3. Metodologia

### 3.1 Estratégia de desenvolvimento

O desenvolvimento do DPDnano-Lite foi conduzido em torno de uma arquitetura congelada, isto é, uma versão funcionalmente consolidada sobre a qual passaram a incidir documentação, verificação e análise de resultados. Essa estratégia foi importante para evitar deriva entre a descrição textual do sistema e a implementação efetivamente testada.

O núcleo arquitetural foi construído em Verilog-2001, com organização modular, convenções explícitas de largura de palavra e separação rigorosa entre transformação aritmética, conversão de escala e saturação final. A plataforma de referência foi a Tang Nano 4K, baseada no dispositivo Gowin GW1NSR-LV4C (SIPEED, 2026).

### 3.2 Organização da validação

A validação foi estruturada em duas frentes complementares:

1. **Testes funcionais TC001 a TC010**, voltados à corretude lógica e temporal da arquitetura congelada.
2. **Ensaios TMQ001 a TMQ013**, voltados à caracterização de faixa dinâmica, linearidade, resposta polinomial, erro de quantização, precisão numérica, estabilidade temporal, simetria, repetibilidade e limites operacionais.

Essa separação metodológica permite distinguir entre a pergunta “a arquitetura está correta?” e a pergunta “como essa arquitetura se comporta sob diferentes regimes de operação?”. A primeira é respondida pelos TCxxx; a segunda, pelos TMQxxx.

### 3.3 Ambiente experimental

O ambiente de verificação foi desenvolvido em ModelSim, com testbenches autoavaliáveis escritos em Verilog. Sempre que pertinente, os ensaios também produziram artefatos auxiliares, como relatórios Markdown, arquivos CSV e gráficos SVG. Essa estratégia amplia a rastreabilidade experimental e fortalece a análise além do binômio PASS/FAIL (BERGERON, 2000; BHASKER; CHADHA, 2009).

## 4. Arquitetura DPDnano-Lite

### 4.1 Visão geral

A arquitetura congelada do DPDnano-Lite implementa o seguinte fluxo funcional:

`x[n] -> ramo linear + ramo cúbico -> acumulação -> rounding -> saturator -> y[n]`

Em termos matemáticos, a ideia central pode ser representada por:

`y[n] = sat{ round[ c1.x[n] + c3.x[n]|x[n]|^2 ] }`

na qual `x[n]` é a amostra complexa de entrada, `c1` é o coeficiente complexo do ramo linear, `c3` é o coeficiente complexo do ramo cúbico, `round(.)` representa a conversão aritmética de escala e `sat(.)` representa a limitação final ao intervalo de saída.

O módulo de topo `dpd_core` integra os módulos `complex_mult`, `poly_kernel`, `poly_branch`, `rounding` e `saturator`, além da lógica registrada de alinhamento e acumulação. Embora o repositório contenha módulos auxiliares como `fixed_mult`, `complex_add`, `iq_delay`, `coeff_bank` e `mult_generic`, o fluxo funcional congelado validado concentra-se no conjunto mínimo que participa do datapath ativo.

### 4.2 Datapath ativo

O datapath ativo inicia quando a amostra complexa de entrada, em Q1.15, é apresentada juntamente com os coeficientes complexos de primeira e terceira ordem, também em Q1.15. A partir daí, o processamento se bifurca em dois ramos:

1. **Ramo linear**: o módulo `complex_mult` calcula a multiplicação complexa entre a amostra e o coeficiente `c1`.
2. **Ramo cúbico**: o módulo `poly_kernel` calcula `|x[n]|^2` e forma o termo `x[n]|x[n]|^2`; em seguida, `poly_branch` aplica o coeficiente complexo `c3` e reescala o resultado para o formato do acumulador.

Como o ramo cúbico contém mais estágios internos do que o ramo linear, o projeto realiza alinhamento temporal explícito do ramo linear antes da recomposição. A soma não é feita por um somador complexo externo no caminho principal; ela é implementada localmente em `dpd_core` como acumulação registrada em largura estendida.

Após a acumulação, o resultado segue para o módulo `rounding`, responsável exclusivamente por arredondamento aritmético e conversão de escala. Por fim, o módulo `saturator` aplica a limitação de faixa, registra a saída final e produz a sinalização de overflow.

Essa separação de responsabilidades é uma das decisões arquiteturais mais importantes do trabalho. Ao concentrar a conversão de escala em `rounding` e reservar a `saturator` apenas a saturação final, o projeto simplifica a análise numérica e torna a verificação mais objetiva.

### 4.3 Representação numérica

Toda a arquitetura foi implementada em ponto fixo. Na interface externa, entrada, saída e coeficientes utilizam formato Q1.15. Internamente, as larguras de palavra crescem para preservar precisão durante a formação do termo polinomial e a acumulação final. A configuração numérica centralizada foi congelada no arquivo `config.vh`.

Os principais formatos observados na arquitetura são:

| Sinal | Formato |
|---|---|
| Entrada complexa | Q1.15 |
| Coeficientes complexos | Q1.15 |
| `|x|^2` | Q3.30 |
| Termo cúbico `x|x|^2` | Q4.45 |
| Ramos linear e cúbico reescalados | Q3.30 |
| Acumulador | Q4.30 |
| Saída após rounding | Q1.15 |
| Saída final | Q1.15 |

Essa política numérica evidencia uma escolha de projeto importante: em vez de truncar prematuramente os resultados intermediários, o DPDnano-Lite preserva precisão ao longo dos estágios internos e posterga a redução de escala para o ponto semanticamente correto do fluxo. O benefício é menor erro acumulado; o custo é uma largura de palavra interna maior, ainda assim compatível com a proposta Lite.

### 4.4 Pipeline e sincronização temporal

A arquitetura é síncrona, monodomínio e orientada a fluxo. Há registro explícito na saída de `complex_mult`, `poly_kernel`, `poly_branch`, na acumulação em `dpd_core`, na saída de `rounding` e na saída final de `saturator`. Essa organização resulta em latência fixa de cinco ciclos entre a aceitação da amostra válida e a disponibilização da saída correspondente (BHASKER; CHADHA, 2009).

Após o enchimento inicial do pipeline, o sistema admite uma nova amostra válida por ciclo de clock. Em outras palavras, a latência absoluta não é mínima, mas a vazão sustentada é adequada para processamento contínuo em banda base. Essa é uma escolha coerente com a filosofia do projeto: buscar previsibilidade e realizabilidade prática, e não agressividade máxima de frequência ou paralelismo.

## 5. Implementação RTL

### 5.1 Módulos centrais

Os módulos centrais do caminho de dados validado são:

1. `dpd_core`
2. `complex_mult`
3. `poly_kernel`
4. `poly_branch`
5. `rounding`
6. `saturator`

O módulo `dpd_core` define o contrato funcional da arquitetura, integra os ramos, realiza alinhamento temporal e implementa a acumulação registrada. O módulo `complex_mult` materializa o ganho complexo linear. O módulo `poly_kernel` torna explícita a formação do termo não linear `x|x|^2`. O módulo `poly_branch` aplica o coeficiente cúbico e conforma o ramo não linear ao formato do acumulador. O módulo `rounding` estabelece a fronteira entre precisão interna estendida e formato final de saída. O módulo `saturator` isola o tratamento de saturação como fenômeno final e monitorável.

### 5.2 Módulos auxiliares e escopo da versão congelada

Os módulos `fixed_mult`, `complex_add`, `iq_delay`, `coeff_bank` e `mult_generic` permanecem no repositório como infraestrutura de suporte, biblioteca aritmética, documentação evolutiva e base para futuras expansões. Contudo, eles não compõem o fluxo funcional principal utilizado na campanha de validação congelada.

Essa distinção é importante porque reforça a fidelidade científica da descrição. Em arquiteturas acadêmicas, é comum que o repositório preserve variantes, blocos auxiliares e caminhos de evolução. No entanto, a análise técnica precisa deixar claro quais elementos participaram efetivamente do sistema testado e quais pertencem ao ecossistema ampliado do projeto.

## 6. Resultados experimentais

### 6.1 Validação funcional TC001 a TC010

Os testes funcionais TC001 a TC010 cobriram reset, entrada nula, regime linear positivo e negativo, ativação do ramo cúbico, saturação positiva, saturação negativa, flags de overflow, latência de pipeline e benchmark de throughput.

Em conjunto, esses testes confirmaram que:

1. A arquitetura parte de estado conhecido e não produz atividade espúria após reset.
2. A entrada nula é preservada como saída nula.
3. O caminho linear opera corretamente para diferentes sinais e polaridades.
4. O ramo cúbico participa de forma funcional e observável da resposta total.
5. A política de saturação é coerente nos extremos positivo e negativo.
6. A sinalização de overflow acompanha corretamente eventos de extrapolação.
7. A latência observada coincide com a organização pipeline projetada.
8. O sistema sustenta entrega contínua de amostras em campanhas longas.

Esse conjunto de evidências estabelece a corretude comportamental mínima da arquitetura congelada e forma a base sobre a qual os ensaios TMQ podem ser interpretados.

### 6.2 Caracterização nominal e numérica TMQ001 a TMQ006

Os ensaios TMQ001 a TMQ006 forneceram resultados quantitativos centrais para a avaliação do DPDnano-Lite.

No **TMQ001**, a arquitetura processou **131072 vetores**, com **100% de entrega**, **latência de 5 ciclos** e **zero eventos de overflow** sob a configuração nominal adotada. Esse resultado indica que, em regime moderado, o sistema opera integralmente dentro de uma região segura.

No **TMQ002**, com o ramo cúbico desabilitado, foram obtidos **512 pontos aprovados de 512 pontos avaliados**, **erro absoluto máximo nulo** e **zero overflow**, confirmando a fidelidade do regime linear.

No **TMQ003**, com ativação significativa do ramo cúbico, foram observados `max_linear_abs = 12288`, `max_poly_abs = 3456` e `max_output_abs = 15744`, sem overflow. O resultado mostra que a parcela cúbica não é apenas nominal: ela contribui de forma mensurável para a saída total.

No **TMQ004**, dedicado ao erro de quantização, o **erro máximo absoluto permaneceu abaixo de 0,5 LSB**, com distribuição centrada, o que é compatível com uma política de arredondamento bem comportada.

No **TMQ005**, em cenário complexo com coeficientes reais e imaginários ativos, foram observados **erro máximo de aproximadamente 1,5 LSB por componente**, **erro máximo em magnitude de cerca de 1,57 LSB** e **erro RMS de magnitude inferior a 0,007%**. Isso demonstra elevada fidelidade numérica mesmo sob interação complexa entre ramos.

No **TMQ006**, a caracterização temporal confirmou `latency_min = 5`, `latency_max = 5` e `latency_avg = 5`, com vazão observada de aproximadamente **0,99939 vetores por ciclo**, o que, na prática, corresponde à entrega de uma amostra válida por ciclo após enchimento do pipeline.

### 6.3 Estabilidade, estatística, simetria e repetibilidade TMQ007 a TMQ010

Os ensaios TMQ007 a TMQ010 aprofundaram a análise de robustez operacional.

No **TMQ007**, com **100000 amostras**, todos os indicadores de falha monitorados permaneceram nulos: `xz_errors`, `logical_nan_errors`, `glitch_errors`, `stall_errors` e `oscillation_flags`. O maior comprimento de repetição de saída observado foi igual a 1, indicando ausência de travamento ou repetição artificial.

No **TMQ008**, também com **100000 amostras**, foram observadas médias próximas de zero, variâncias semelhantes entre I e Q e histogramas equilibrados, sugerindo ausência de viés estatístico macroscópico e boa simetria global do processamento complexo.

No **TMQ009**, com **8192 pares de amostras simétricas**, o erro máximo absoluto de simetria foi de **1 LSB por componente**, equivalente a cerca de `3,05e-5` em valor real. O resultado mostra que a implementação em ponto fixo preserva a simetria esperada do modelo com erro mínimo.

No **TMQ010**, dedicado à repetibilidade sob estresse, foram realizadas **1000 repetições** de uma sequência de **1024 amostras**, totalizando **1024000 vetores**. O resultado foi particularmente forte: `mismatch_count = 0`, isto é, **100% de repetibilidade bit a bit**, mesmo com **409000 saídas saturadas** e taxa de overflow próxima de **40%**. Esse é um dos resultados mais relevantes do trabalho, pois mostra que saturação frequente não implica comportamento errático; o sistema permanece completamente determinístico.

### 6.4 Sensibilidade a coeficientes e limites operacionais TMQ011 a TMQ013

Os ensaios TMQ011 a TMQ013 investigaram fronteiras operacionais da arquitetura.

No **TMQ011**, foram avaliadas **4225 combinações de coeficientes reais**, das quais **3105** foram classificadas como seguras e **1120** como inseguras, resultando em **73,49% de combinações seguras** no espaço testado. O resultado mostra que a região operacional sem saturação é ampla, porém não irrestrita.

No **TMQ012**, no domínio complexo, foram observadas **42 combinações seguras** e **39 inseguras**, com razão de segurança de aproximadamente **51,85%**. Em comparação com o caso real, a fronteira segura torna-se mais estreita, evidenciando a influência da geometria fasorial sobre a margem operacional.

No **TMQ013**, o sistema foi submetido a estresse crescente de amplitude. O ensaio identificou **primeira saturação no nível 41**, **primeira saturação persistente no nível 44**, **último nível ainda seguro igual a 40** e **amplitude segura máxima de aproximadamente 0,828125**, enquanto a primeira saturação surgiu em aproximadamente **0,845703125**. A taxa global de segurança observada foi de **88,54%**. Esse resultado oferece um limiar operacional objetivo e diferencia saturação pontual de saturação persistente, enriquecendo a interpretação do comportamento do sistema.

## 7. Discussão

Os resultados obtidos permitem interpretar o DPDnano-Lite sob três perspectivas complementares.

A primeira é a **perspectiva arquitetural**. A escolha por um modelo de baixa ordem, estruturado em ramo linear e ramo cúbico, mostrou-se suficiente para produzir uma implementação tecnicamente significativa sem exigir uma topologia excessivamente extensa. A modularidade do fluxo, a separação entre `rounding` e `saturator` e o alinhamento temporal explícito entre os ramos contribuíram para a clareza estrutural e para a verificabilidade do sistema.

A segunda é a **perspectiva numérica**. A decisão de preservar precisão interna estendida e postergar a conversão de escala para o estágio adequado resultou em erros baixos e controlados. O desempenho observado nos ensaios TMQ004 e TMQ005 indica que a simplificação arquitetural não foi obtida à custa de degradação numérica incompatível com o uso prático.

A terceira é a **perspectiva temporal e operacional**. A latência fixa de cinco ciclos, a vazão sustentada próxima de uma amostra por ciclo, a ausência de comportamento espúrio em campanhas longas e a repetibilidade bit a bit sob estresse severo indicam que o DPDnano-Lite é mais do que um protótipo lógico. Trata-se de uma arquitetura com comportamento suficientemente previsível para sustentar tanto análise acadêmica rigorosa quanto futuras integrações experimentais.

Ao mesmo tempo, os testes de sensibilidade e limite operacional deixam claro que a arquitetura não é arbitrariamente ilimitada. Como todo sistema em ponto fixo com faixa dinâmica finita, ela impõe fronteiras reais à parametrização admissível. Longe de ser uma fragilidade metodológica, esse resultado fortalece o valor científico do trabalho, pois transforma a avaliação em investigação de margem operacional, e não apenas em demonstração de funcionamento nominal.

## 8. Conclusão

Este artigo apresentou o DPDnano-Lite, uma arquitetura RTL compacta para predistorção digital em FPGA de pequeno porte. A proposta foi construída a partir de um recorte arquitetural deliberadamente enxuto, baseado em um ramo linear e um ramo cúbico de terceira ordem, com implementação em Verilog-2001 e aritmética integralmente em ponto fixo.

Os resultados experimentais mostram que a arquitetura:

1. É funcionalmente correta em sua campanha de testes básicos.
2. Possui latência fixa de cinco ciclos.
3. Sustenta vazão de uma amostra válida por ciclo após enchimento do pipeline.
4. Apresenta erro de quantização controlado e elevada fidelidade numérica.
5. Permanece estável e determinística em campanhas longas e sob estresse com saturação.
6. Possui fronteiras operacionais mensuráveis e tecnicamente interpretáveis.

Com isso, o DPDnano-Lite cumpre seu objetivo central: demonstrar a viabilidade de uma arquitetura de predistorção digital compacta, modular, verificável e compatível com hardware reconfigurável de recursos limitados.

Como trabalhos futuros, destacam-se a incorporação de memória explícita, ordens polinomiais superiores, parametrização interna mais sofisticada, integração com fluxos adaptativos de atualização de coeficientes e validação em experimentos hardware-in-the-loop ou em bancada com amplificador real.

## Agradecimentos

Os autores agradecem ao orientador, à instituição de ensino e aos colegas de laboratório pelo suporte técnico e acadêmico durante o desenvolvimento do trabalho.

## Referências

BERGERON, Janick. *Writing Testbenches: Functional Verification of HDL Models*. 2. ed. Boston: Kluwer Academic Publishers, 2000.

BHASKER, J.; CHADHA, Rakesh. *Static Timing Analysis for Nanometer Designs: A Practical Approach*. New York: Springer, 2009.

DING, Lei; ZHOU, Guo Tong; MORGAN, Dennis R.; MA, Zhengxiang; KENNEY, John S.; KIM, Jaehyeong; GIARDINA, Charles R. A robust digital baseband predistorter constructed using memory polynomials. *IEEE Transactions on Communications*, v. 52, n. 1, p. 159-165, 2004.

GILABERT, Pere L.; DING, Lei. Digital predistortion for power amplifiers. In: CHANG, Kai (ed.). *Encyclopedia of RF and Microwave Engineering*. Hoboken: Wiley, 2024.

LI, Wantao; MONTORO, Gabriel; GILABERT, Pere L. GPU versus FPGA implementation of a digital predistortion linearizer for wideband radiofrequency power amplifiers. *AEU - International Journal of Electronics and Communications*, v. 174, 155040, 2024.

MORGAN, Dennis R.; MA, Zhengxiang; KENNEY, John S.; KIM, Jaehyeong; GIARDINA, Charles R. A generalized memory polynomial model for digital predistortion of RF power amplifiers. *IEEE Transactions on Signal Processing*, v. 54, n. 10, p. 3852-3860, 2006.

SIPEED. Tang Nano 4K. Sipeed Wiki. Disponível em: <https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-4K/Nano-4K.html>. Acesso em: 29 jul. 2026.

ZHU, Anding. Behavioral modeling for digital predistortion of RF power amplifiers: from Volterra series to CPWL functions. In: *IEEE Topical Conference on Power Amplifiers for Wireless and Radio Applications (PAWR)*. Austin: IEEE, 2016.

## Observações para submissão

1. Substituir os campos de autores, instituição e e-mails.
2. Adequar o estilo das referências ao template final do evento ou periódico.
3. Inserir as figuras mais fortes da campanha experimental, especialmente TMQ002, TMQ003, TMQ004, TMQ010, TMQ011, TMQ012 e TMQ013.
4. Se o destino for congresso curto, condensar as Seções 2 e 5 e manter foco em arquitetura, resultados e discussão.
