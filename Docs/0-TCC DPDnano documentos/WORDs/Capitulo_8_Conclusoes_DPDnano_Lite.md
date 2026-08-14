# CAPÍTULO 8 - CONCLUSÕES E TRABALHOS FUTUROS

## 8.1 Considerações iniciais

Este trabalho teve como objetivo central investigar a viabilidade de uma arquitetura compacta de Predistorção Digital, denominada DPDnano-Lite, orientada à implementação em FPGA com recursos limitados. Ao longo do desenvolvimento, buscou-se não apenas propor uma formulação arquitetural simplificada, mas também demonstrar, de maneira tecnicamente rastreável, que essa formulação poderia ser convertida em uma implementação RTL sintetizável, verificável e experimentalmente validável em hardware real.

Ao final da trajetória descrita nos capítulos anteriores, pode-se afirmar que esse objetivo foi atingido. O DPDnano-Lite deixou de ser apenas uma formulação teórica inspirada em modelos polinomiais com memória e passou a constituir um núcleo digital completo, com organização modular explícita, representação em ponto fixo, pipeline definido, infraestrutura de teste em FPGA e campanha experimental suficientemente ampla para sustentar conclusões técnicas consistentes. Essa transição entre formulação matemática, implementação RTL e validação em hardware representa, por si só, um dos resultados mais relevantes do trabalho.

Também é importante destacar que a conclusão deste TCC não se apoia apenas em sucesso pontual de laboratório. O projeto foi conduzido de forma incremental, com congelamento de versões, organização do ambiente de simulação, padronização da infraestrutura experimental e repetição dos testes em FPGA real. Essa abordagem permitiu que as conclusões aqui apresentadas não fossem baseadas em observações casuais, mas em um corpo progressivamente consolidado de evidências, o que fortalece a robustez acadêmica e técnica do resultado final.

## 8.2 Retomada do problema e da proposta desenvolvida

O ponto de partida deste trabalho foi a tensão clássica entre linearidade e eficiência em sistemas de amplificação de potência, bem como o papel da Predistorção Digital como técnica de compensação de não linearidades em transmissores modernos (DING et al., 2004; GILABERT; DING, 2024). Em sistemas convencionais, a elevação da linearidade costuma vir acompanhada de aumento de custo computacional, uso intensivo de recursos e crescimento da complexidade de implementação, especialmente quando se pretende empregar modelos comportamentais mais abrangentes, como extensões do Memory Polynomial ou estruturas de maior ordem (MORGAN et al., 2006; ZHU, 2016).

Diante desse cenário, a proposta do DPDnano-Lite foi deliberadamente orientada à especialização arquitetural. Em vez de perseguir generalidade máxima, o trabalho concentrou esforços em uma formulação reduzida e objetivamente implementável em FPGA compacta, preservando os mecanismos essenciais de resposta não linear em magnitude e fase, mas reduzindo a complexidade estrutural a um patamar compatível com a plataforma Tang Nano 4K (SIPEED, 2026; LI; MONTORO; GILABERT, 2024).

Essa decisão de engenharia permeia todo o trabalho. A arquitetura resultante não pretende competir com soluções de DPD de alta complexidade destinadas a plataformas mais ricas em DSPs, memória e largura de banda interna. Seu mérito está em demonstrar que uma resposta polinomial especializada, com comportamento ainda tecnicamente interpretável, pode ser implementada com estrutura modular enxuta, custo controlado e fluxo de validação coerente em uma FPGA de pequeno porte. A proposta, portanto, não é apenas um exercício de redução de modelo, mas uma investigação concreta sobre o que é possível sustentar experimentalmente quando os recursos de hardware são intencionalmente restritos.

## 8.3 Síntese das principais contribuições do trabalho

Uma primeira contribuição deste trabalho reside na própria concepção da arquitetura DPDnano-Lite. A partir da fundamentação teórica sobre Predistorção Digital e modelos polinomiais, foi desenvolvida uma formulação especializada que preserva a contribuição linear e a contribuição cúbica dominante, incluindo tratamento complexo para permitir observação controlada de efeitos AM/AM e AM/PM. Essa especialização foi fundamental para tornar o projeto compatível com uma plataforma FPGA compacta sem descaracterizar completamente a natureza comportamental da técnica.

Uma segunda contribuição foi a tradução dessa formulação para uma implementação RTL modular em Verilog. O trabalho não se limitou a descrever o modelo matemático; ele detalhou a organização dos módulos, a representação numérica em ponto fixo, o encadeamento do pipeline, o papel do `dpd_core` e a integração entre blocos auxiliares. Com isso, o TCC oferece não apenas uma ideia arquitetural, mas um núcleo digital efetivamente estruturado, passível de síntese, depuração e evolução.

Uma terceira contribuição está na construção do ambiente de verificação funcional e experimental. Foram organizados testbenches, testes funcionais, testes de métricas qualitativas e, posteriormente, uma campanha ampla de hardware envolvendo os ensaios HW001 a HW024. Essa bateria permitiu validar desde a infraestrutura de comunicação e bring-up até curvas AM/AM, curvas AM/PM, compressão, saturação, janela operacional, latência, throughput e reprodutibilidade estatística.

Uma quarta contribuição, particularmente importante do ponto de vista científico, foi a delimitação explícita da faixa de operação realmente validada em hardware real. O trabalho mostrou que não basta sintetizar ou fechar temporização em frequências nominais mais altas; é necessário demonstrar que a resposta experimental permanece coerente, monotônica quando apropriado, estatisticamente consistente e temporalmente previsível. Ao estabelecer 60 MHz como frequência final robustamente validada, o TCC transforma uma decisão prática de projeto em conclusão experimental fundamentada.

Por fim, uma quinta contribuição relevante foi a documentação sistemática do processo. O projeto passou por congelamento de versões, organização dos testes em pacotes independentes, geração de CSVs e figuras, elaboração de capítulos técnicos, material para apresentação e estruturação de um acervo reexecutável de validação. Em um contexto de TCC, isso tem valor particular porque amplia a rastreabilidade do trabalho e facilita sua continuidade por outros integrantes ou por investigações futuras.

## 8.4 Atendimento aos objetivos propostos

Considerando os objetivos formulados no início do trabalho, é possível afirmar que eles foram atendidos de maneira satisfatória.

O primeiro objetivo, relacionado ao estudo da fundamentação teórica de Predistorção Digital, modelos polinomiais, não linearidades de amplificadores e critérios de implementação em FPGA, foi cumprido ao longo dos capítulos de base conceitual. Esses capítulos forneceram o suporte necessário para justificar a escolha de uma formulação simplificada, tecnicamente defensável e alinhada ao foco em hardware com recursos limitados.

O segundo objetivo, consistente em propor uma arquitetura digital própria, foi atendido com a definição do DPDnano-Lite. A arquitetura resultante apresentou separação clara entre ramo linear, ramo cúbico e estágios auxiliares de multiplicação, arredondamento e saturação. Mais do que isso, a proposta foi descrita em nível suficiente para permitir compreensão estrutural e implementação prática.

O terceiro objetivo, correspondente à implementação RTL sintetizável em Verilog, também foi alcançado. O núcleo foi efetivamente implementado, organizado em módulos e integrado à infraestrutura de top-level, clock, interface de teste e comunicação host-FPGA. A existência de uma versão congelada validada (`rtl_v3_1`) demonstra que o trabalho não permaneceu em estágio exploratório, mas chegou a uma configuração final claramente identificável.

O quarto objetivo, ligado à verificação funcional em ambiente controlado, foi atendido por meio da campanha de simulação e dos testes TC, TMQ e correlatos desenvolvidos ao longo do capítulo de verificação. Esses ensaios foram importantes para depurar a lógica antes de sua submissão à FPGA real.

O quinto objetivo, talvez o mais exigente do ponto de vista experimental, consistia em validar a arquitetura em hardware real. Esse objetivo foi atendido de maneira abrangente pelos testes HW001 a HW024. A campanha mostrou que a arquitetura opera corretamente em 60 MHz, reproduz curvas coerentes de magnitude e fase, sustenta fluxo contínuo prolongado, apresenta latência fixa de 6 ciclos e alcança throughput próximo a 60 MS/s, além de demonstrar reprodutibilidade estatística em campanhas repetidas de grande volume de dados.

Assim, o conjunto dos objetivos não apenas foi formalmente cumprido, mas também foi articulado de modo coerente: a teoria sustentou a arquitetura, a arquitetura sustentou a implementação, a implementação sustentou a verificação, e a verificação sustentou a validação experimental. Essa cadeia de coerência é um dos pontos fortes do trabalho.

## 8.5 Conclusões técnicas sobre a arquitetura DPDnano-Lite

Do ponto de vista arquitetural, a principal conclusão deste TCC é que o DPDnano-Lite constitui uma solução viável para implementação de Predistorção Digital especializada em FPGA de pequeno porte, desde que se reconheçam explicitamente seus limites de operação. A arquitetura mostrou ser capaz de reproduzir, em hardware real, comportamentos compatíveis com resposta AM/AM, rotação AM/PM, compressão, saturação e sensibilidade paramétrica, sem exigir uma infraestrutura computacional incompatível com a plataforma-alvo.

Os resultados experimentais indicaram que a especialização do modelo foi suficiente para preservar comportamento útil e tecnicamente interpretável. Isso significa que a redução de complexidade não eliminou os mecanismos essenciais que se desejava observar no predistorcedor. A arquitetura manteve a distinção funcional entre contribuição linear e cúbica, mostrou resposta de fase associada a coeficientes complexos e permitiu delimitar regiões seguras e regiões críticas no espaço de coeficientes.

Outro ponto importante é que a campanha evidenciou, de forma bastante clara, a existência de limitantes estruturais. A não monotonicidade observada em certas regiões compressivas mostrou que o limite do DPDnano-Lite não é definido apenas por overflow ou saturação numérica. Existe também um limite comportamental, associado à perda de ganho incremental positivo, que restringe a utilidade prática de determinadas combinações de coeficientes. Essa observação enriquece a interpretação da arquitetura e afasta leituras simplistas sobre sua faixa operacional.

Também merece destaque a conclusão sobre frequência de operação. O trabalho demonstrou que, embora tenham sido tentadas versões experimentais visando frequências mais altas, a condição mais robusta e defensável em hardware real foi a operação em 60 MHz. Isso não deve ser visto como fracasso do projeto, mas como resultado honesto de engenharia: a arquitetura foi validada até o ponto em que o conjunto de métricas funcionais, temporais e estatísticas permaneceu consistentemente confiável.

Em síntese, a arquitetura DPDnano-Lite mostrou-se tecnicamente bem-sucedida dentro do escopo a que se propôs: oferecer uma implementação compacta, modular e verificável de predistorção digital em FPGA com recursos limitados, com validade experimental demonstrada e limites operacionais explicitamente caracterizados.

## 8.6 Conclusões sobre a validação experimental

Do ponto de vista metodológico e experimental, a campanha realizada ao longo do trabalho constitui um resultado relevante por si só. O sistema não foi apenas sintetizado; ele foi submetido a uma sequência progressiva de ensaios que começaram pela confiabilidade da infraestrutura e culminaram em testes estatísticos prolongados de fluxo contínuo.

Os ensaios HW001 a HW011 mostraram que a plataforma de comunicação, os top-levels de teste, a lógica de controle, os sinais de diagnóstico e o ambiente de captura de dados alcançaram maturidade suficiente para sustentar os experimentos principais. Esse bloco inicial foi essencial para que os resultados posteriores não fossem interpretados como possíveis artefatos de integração host-FPGA.

Os ensaios HW012 a HW021 permitiram caracterizar o comportamento do núcleo sob múltiplas perspectivas: influência da frequência, limites de saturação, rotação complexa, compressão, ponto de 1 dB, ganho incremental, janela operacional e sensibilidade paramétrica. Esse conjunto transformou o capítulo experimental em algo mais robusto do que um simples “rodou na FPGA”: ele mostrou como a arquitetura responde, onde responde bem e onde começa a perder previsibilidade.

Finalmente, os ensaios HW022 a HW024 mostraram que o DPDnano-Lite é capaz de operar como sistema temporalmente consistente. A confirmação de latência fixa de 6 ciclos, jitter nulo, throughput próximo a 60 MS/s, integridade de fluxo em campanhas longas e reprodutibilidade estatística sob repetição reforça que a proposta atingiu um nível de maturidade experimental significativo para o contexto do trabalho.

Portanto, a validação experimental não deve ser entendida apenas como etapa final de verificação, mas como componente essencial da contribuição do TCC. Foi ela que permitiu converter hipóteses arquiteturais em conclusões tecnicamente sustentáveis.

## 8.7 Limitações do trabalho

Como todo projeto de engenharia, este trabalho apresenta limites que precisam ser explicitados para que suas conclusões sejam corretamente interpretadas.

O primeiro limite refere-se à frequência máxima experimentalmente validada. Embora tenham sido investigadas alternativas de pipeline e refinamentos estruturais visando ampliar a frequência de operação, a campanha final mostrou que a condição de 60 MHz foi a mais confiável em hardware real. Assim, o projeto não demonstrou, no estado atual, operação robusta em torno de 100 MHz com a mesma consistência funcional e estatística.

O segundo limite diz respeito à especialização do modelo. A escolha por uma formulação reduzida foi deliberada e coerente com o objetivo de implementação compacta, mas isso naturalmente restringe a abrangência comportamental da arquitetura quando comparada a modelos mais gerais e mais custosos. Em outras palavras, o DPDnano-Lite privilegia implementabilidade e rastreabilidade sobre abrangência máxima de modelagem.

O terceiro limite está associado ao escopo da validação. O trabalho caracterizou com profundidade o núcleo digital em FPGA real, mas não teve como objetivo principal o fechamento de uma bancada completa de RF com amplificador físico, medição de ACPR, EVM ou linearização final em sistema de transmissão. Portanto, as conclusões aqui obtidas dizem respeito principalmente à validade do predistorcedor como arquitetura digital embarcada e como núcleo sintetizável de compensação não linear.

O quarto limite diz respeito à própria plataforma adotada. O uso da Tang Nano 4K foi coerente com a proposta de restrição de recursos, mas também impôs margens estreitas de temporização, área e organização interna de clock. Isso significa que parte das conclusões de desempenho está intrinsecamente vinculada ao contexto da FPGA escolhida.

Além disso, a campanha revelou um limitante importante de orçamento de DSP. Em alguns ensaios e variantes arquiteturais, especialmente quando se desejava combinar maior flexibilidade paramétrica, coeficientes complexos e seleção dinâmica de perfis, a inferência de multiplicadores dedicados se aproximava rapidamente do teto aceitável para o dispositivo. Isso obrigou o projeto a adotar escolhas específicas para caber na Tang Nano 4K, inclusive selecionando combinações de coeficientes explicitamente ajustadas para respeitar o limite prático de DSP observado durante a síntese.

Esse ponto ficou particularmente claro nos testes em que a lógica de seleção dinâmica de perfis podia alterar a inferência de recursos em relação às versões mais simples. Em vez de apenas avaliar se a curva resultante era correta, tornou-se necessário verificar também se o projeto continuava sintetizável e roteável dentro do orçamento do dispositivo. Em outras palavras, a plataforma não limitou apenas a frequência de operação; ela também limitou o grau de generalidade que podia ser incorporado ao núcleo sem descaracterizar o foco de implementação compacta.

Reconhecer esses limites não enfraquece o trabalho. Pelo contrário, qualifica suas conclusões e aumenta sua credibilidade, pois mostra com clareza o que foi demonstrado, em que condições foi demonstrado e quais aspectos permanecem em aberto para continuidade da pesquisa.

## 8.8 Trabalhos futuros e possibilidades de melhoria

Os resultados obtidos ao longo deste TCC abrem diversas possibilidades de continuidade, tanto do ponto de vista científico quanto do ponto de vista de engenharia de implementação.

Uma primeira linha de continuidade consiste no aprofundamento da otimização temporal da arquitetura. As tentativas exploratórias realizadas em versões experimentais posteriores mostraram que há espaço para investigação adicional em redistribuição de pipeline, reorganização do ramo cúbico, reavaliação de arredondamento e saturação e possível particionamento mais agressivo do caminho crítico. Um trabalho futuro pode explorar essas alternativas de forma mais sistemática, sempre confrontando ganhos de Fmax com ganhos reais em operação experimental.

Uma segunda possibilidade é a migração da arquitetura para plataformas FPGA com maior disponibilidade de recursos. Essa direção se torna especialmente relevante à luz da limitação de DSP observada na Tang Nano 4K. Durante o desenvolvimento, algumas variantes com maior flexibilidade de coeficientes e seleção dinâmica de perfis exigiram cuidado explícito para não ultrapassar o teto prático de DSP aceito pelo dispositivo. Em uma FPGA com orçamento mais confortável de multiplicadores dedicados, seria possível investigar até que ponto a arquitetura pode recuperar generalidade sem abrir mão de coerência funcional. Tal comparação também seria útil para separar aquilo que é limite intrínseco do DPDnano-Lite daquilo que é limite específico da plataforma utilizada neste TCC.

Uma terceira linha promissora é a ampliação do modelo comportamental. Embora o DPDnano-Lite tenha se mostrado eficiente dentro da proposta de simplificação, estudos futuros podem explorar a inclusão de termos adicionais, memórias mais elaboradas, estruturas generalizadas inspiradas no Generalized Memory Polynomial ou mecanismos de adaptação dinâmica de coeficientes, desde que se preserve um compromisso explícito com o custo de implementação (MORGAN et al., 2006; LI; MONTORO; GILABERT, 2024). Nesse contexto, torna-se natural distinguir duas trilhas de continuidade: uma versão compacta, otimizada para FPGAs restritas, e uma versão mais próxima de um DPD standard, voltada a plataformas com maior disponibilidade de DSPs e área lógica.

Uma quarta continuidade natural está na integração com uma bancada RF completa. Isso envolve utilizar o núcleo validado em FPGA em conjunto com um amplificador físico e avaliar métricas clássicas de linearização, como ACPR, EVM e espectro de saída, aproximando o projeto de um cenário mais próximo de aplicação em telecomunicações. Essa etapa seria particularmente importante para transformar a validação estrutural e comportamental aqui obtida em validação de desempenho sistêmico de transmissão.

Uma quinta possibilidade é o desenvolvimento de mecanismos automatizados de calibração e ajuste de coeficientes. O trabalho atual concentrou-se em campanhas controladas com parâmetros definidos e varridos de forma organizada. Em continuidade, pode-se investigar técnicas de estimação, atualização ou busca adaptativa de coeficientes, transformando o núcleo em base para sistemas mais autônomos de compensação não linear.

Também é possível expandir a infraestrutura experimental construída. A organização dos testes em pacotes independentes, a geração sistemática de CSVs e figuras e a padronização do fluxo de bancada criaram uma base propícia para futuras campanhas comparativas, inclusive envolvendo novas arquiteturas, novas versões do núcleo ou novos dispositivos-alvo.

Assim, os trabalhos futuros não decorrem de lacunas acidentais, mas do próprio valor da plataforma construída. O TCC estabeleceu uma base concreta sobre a qual diferentes linhas de evolução podem ser apoiadas.

## 8.9 Considerações finais

O DPDnano-Lite demonstrou que é possível desenvolver uma arquitetura de Predistorção Digital especializada, compacta e tecnicamente rastreável para FPGA com recursos limitados, desde que o projeto seja conduzido com equilíbrio entre ambição arquitetural e realismo experimental. Ao longo deste trabalho, a proposta saiu do nível de hipótese conceitual e alcançou uma implementação efetiva, com organização RTL, verificação funcional, validação em FPGA e delimitação transparente de seus limites.

Em termos acadêmicos, o trabalho entrega uma contribuição relevante porque articula teoria, implementação e experimento em um mesmo fio narrativo. Em termos de engenharia, entrega uma arquitetura que efetivamente funciona, foi extensivamente testada e teve sua faixa operacional caracterizada. Em termos de continuidade, entrega uma base madura para novos estudos em otimização temporal, ampliação de modelo e integração com aplicações de RF.

Por essas razões, conclui-se que o DPDnano-Lite atendeu ao propósito deste TCC e constitui uma contribuição válida para a investigação de soluções de Predistorção Digital implementáveis em FPGA compacta. Mais do que apresentar uma solução fechada e definitiva, o trabalho estabelece um ponto de partida sólido e tecnicamente honesto para evoluções futuras.
