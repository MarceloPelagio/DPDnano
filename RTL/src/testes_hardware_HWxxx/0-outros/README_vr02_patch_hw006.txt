DPDnano_Lite_v3_2 - HW006 Input Memory vr02

CORREÇÃO
--------
A versão vr01 zerava todas as 256 palavras durante reset:

for (i=0; i<256; i=i+1)
    input_memory[i] <= 0;

Isso impedia a inferência de BSRAM e fazia a memória virar milhares
de LUTs/flip-flops, excedendo os 4608 LUTs da GW1NSR-4C.

A vr02:
- remove o reset do conteúdo da memória;
- separa a RAM em input_memory_256x32.v;
- usa leitura síncrona;
- adiciona um estado de espera de leitura;
- permite inferência de block RAM.

SUBSTITUIR
----------
Substitua:
protocol_hw006.v

Adicione:
input_memory_256x32.v

Mantenha:
dpdnano_hw006_input_memory_top.v
uart_rx_27m_115200.v
uart_tx_27m_115200.v
dpdnano_hw006_input_memory.cst
dpdnano_hw006_input_memory.sdc
dpdnano_input_memory_hw006.py

IMPORTANTE
----------
A memória não é inicializada no reset. Isso é normal para BSRAM.
O teste Python primeiro escreve os endereços e depois os lê.

Após substituir:
1. Remova a versão antiga de protocol_hw006.v do projeto.
2. Adicione input_memory_256x32.v.
3. Limpe a pasta impl.
4. Rode Synthesize e confira o uso de BSRAM.
5. Rode Place & Route.
6. Grave o novo .fs.
7. Execute o mesmo teste Python HW006.
