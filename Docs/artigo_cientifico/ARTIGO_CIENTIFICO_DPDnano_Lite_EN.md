# DPDnano-Lite: A Compact RTL Fixed-Point Digital Predistortion Architecture for Small FPGAs

**Authors:** [Name of Author 1], [Name of Author 2], [Name of Author 3]  
**Institution:** [Institution Name]  
**Program:** [Program Name]  
**E-mail:** [authors' e-mails]  

## Abstract

This paper presents DPDnano-Lite, a compact RTL architecture for Digital Predistortion (DPD) targeting small FPGA devices. The proposed design materializes, in synthesizable Verilog-2001, a low-order complex polynomial predistorter with reduced structural cost while preserving temporal predictability, numerical discipline, and implementation modularity. The frozen architecture uses a Q1.15 complex input, a linear branch based on complex multiplication, a third-order nonlinear branch, registered accumulation with extended word length, arithmetic rounding, controlled scale conversion, and final saturation. The work was guided by the Tang Nano 4K platform, based on the Gowin GW1NSR-LV4C device, while remaining portable across conventional RTL flows. Experimental validation was organized in two complementary fronts: functional tests TC001 to TC010 and characterization campaigns TMQ001 to TMQ013. The results show a fixed five-cycle latency, one valid sample per cycle after pipeline fill, full vector delivery in extended campaigns, maximum quantization error below 0.5 LSB in the dedicated test, magnitude RMS error below 0.007% in a complex scenario, and bit-exact repeatability even under severe saturation stress. Taken together, these results indicate that DPDnano-Lite is a technically consistent solution for DPD studies and implementations on resource-constrained reconfigurable hardware, while also providing a solid basis for future extensions with explicit memory, higher polynomial orders, and coefficient adaptation.

**Keywords:** digital predistortion, FPGA, fixed-point, Verilog, DPD, RTL architecture.

## 1. Introduction

Power amplifiers employed in radio-frequency transmitters operate under a classical trade-off between linearity and efficiency. As higher energy efficiency is pursued, the likelihood of operation in regions where nonlinear effects become more pronounced also increases, producing envelope distortion, spectral regrowth, and degradation of transmitted signal quality. In this context, digital predistortion has become one of the most relevant strategies for compensating nonlinearities in modern transmission chains (Gilabert and Ding, 2024; Zhu, 2016; Ding et al., 2004).

Despite the conceptual maturity of DPD in the literature, its hardware implementation still requires careful architectural choices. Highly expressive algorithmic solutions may become structurally heavy, especially when they include explicit memory, multiple polynomial branches, and online coefficient adaptation. This difficulty becomes even more significant when the target is not a large FPGA, but a compact platform in which area, DSP blocks, registers, and integration margin are all finite and critical resources (Li, Montoro, and Gilabert, 2024).

DPDnano-Lite emerged precisely in this design space. Instead of starting from a maximalist formulation and reducing it later, the proposal was conceived from the outset as a lean, verifiable, and implementable architecture for a small FPGA. The main objective was not to compete with broader DPD architectures in algorithmic capability, but to demonstrate that a technically consistent digital predistorter can be built in RTL with numerical discipline, predictable timing behavior, and a cost compatible with modest reconfigurable devices.

In this work, the adopted architecture corresponds to a low-order complex polynomial predistorter specialized into a linear branch and a cubic branch applied to the current sample. This choice preserves the functional core of polynomial DPD while drastically reducing structural complexity. The implementation was developed in Verilog-2001, with fully fixed-point arithmetic and a pipeline organization with deterministic latency (Ding et al., 2004; Morgan et al., 2006).

From a scientific perspective, the contribution of this work is not limited to the description of the RTL code. DPDnano-Lite was subjected to a broad experimental campaign composed of directed functional tests and numerical, temporal, statistical, and operational characterization experiments. Therefore, the paper not only presents an architecture, but also documents in a traceable manner how this architecture behaves under different excitation conditions.

Accordingly, the goal of this paper is to present the formulation, implementation, and validation of DPDnano-Lite, highlighting its architectural trade-offs, numerical policy, and the main results observed in simulation.

## 2. Background and Motivation

Polynomial models occupy a central position in the digital predistortion literature because they provide a favorable balance between expressiveness and computational cost. Classical works have shown that memory-polynomial-based structures can robustly capture the nonlinear response of power amplifiers, while generalized formulations extend this capability at the expense of higher structural complexity. In parallel, recent studies on hardware implementation reinforce that model selection cannot be dissociated from the available computational budget (Ding et al., 2004; Morgan et al., 2006; Li, Montoro, and Gilabert, 2024).

In the case of DPDnano-Lite, the design problem was deliberately formulated under constraint. The architecture had to:

1. Be synthesizable in Verilog-2001.
2. Operate entirely in fixed-point arithmetic.
3. Remain modular and verifiable.
4. Be compatible with a small FPGA.
5. Preserve technical meaning as an actual complex polynomial predistorter.

These requirements make it inappropriate to adopt, in the first validated version, an explicit-memory or high-order polynomial structure. Instead, the Lite proposal isolates the essential portion of the phenomenon to be modeled: a linear branch, responsible for the proportional contribution of the signal, and a cubic branch, responsible for the dominant third-order nonlinear component.

This decision should not be interpreted as arbitrary simplification, but rather as a conscious architectural specialization. DPDnano-Lite does not aim to exhaust the literature on DPD behavioral models; instead, it aims to establish a compact, disciplined hardware basis that can be expanded in the future. This cut is particularly appropriate when the goal is to transform theory into a synthesizable, measurable, and auditable core in an academic engineering environment.

## 3. Methodology

### 3.1 Development Strategy

The development of DPDnano-Lite was conducted around a frozen architecture, that is, a functionally consolidated version upon which documentation, verification, and result analysis were based. This strategy was important to avoid divergence between the textual description of the system and the implementation that was actually tested.

The architectural core was built in Verilog-2001, with modular organization, explicit word-length conventions, and strict separation between arithmetic transformation, scale conversion, and final saturation. The reference platform was the Tang Nano 4K, based on the Gowin GW1NSR-LV4C device (SIPEED, 2026).

### 3.2 Validation Organization

Validation was structured in two complementary fronts:

1. **Functional tests TC001 to TC010**, aimed at the logical and temporal correctness of the frozen architecture.
2. **TMQ001 to TMQ013 characterization campaigns**, aimed at dynamic range, linearity, polynomial response, quantization error, numerical precision, temporal stability, symmetry, repeatability, and operational limit characterization.

This methodological separation distinguishes the question “is the architecture correct?” from the question “how does this architecture behave under different operating regimes?”. The former is addressed by the TCxxx tests, whereas the latter is addressed by the TMQxxx campaigns.

### 3.3 Experimental Environment

The verification environment was developed in ModelSim, using self-checking testbenches written in Verilog. Whenever relevant, the experiments also produced auxiliary artifacts such as Markdown reports, CSV files, and SVG plots. This strategy increases experimental traceability and strengthens the analysis beyond the simple PASS/FAIL outcome (Bergeron, 2000; Bhasker and Chadha, 2009).

## 4. DPDnano-Lite Architecture

### 4.1 Overview

The frozen DPDnano-Lite architecture implements the following functional flow:

`x[n] -> linear branch + cubic branch -> accumulation -> rounding -> saturator -> y[n]`

In mathematical terms, the core idea can be represented by:

`y[n] = sat{ round[ c1.x[n] + c3.x[n]|x[n]|^2 ] }`

where `x[n]` is the complex input sample, `c1` is the complex coefficient of the linear branch, `c3` is the complex coefficient of the cubic branch, `round(.)` denotes arithmetic scale conversion, and `sat(.)` denotes final limiting to the output range.

The top-level module `dpd_core` integrates the modules `complex_mult`, `poly_kernel`, `poly_branch`, `rounding`, and `saturator`, as well as the registered alignment and accumulation logic. Although the repository contains auxiliary modules such as `fixed_mult`, `complex_add`, `iq_delay`, `coeff_bank`, and `mult_generic`, the validated frozen functional flow is concentrated in the minimal set that actually participates in the active datapath.

### 4.2 Active Datapath

The active datapath begins when the complex input sample, in Q1.15 format, is presented together with the first-order and third-order complex coefficients, also in Q1.15. From this point, processing is split into two branches:

1. **Linear branch**: the `complex_mult` module computes the complex multiplication between the sample and coefficient `c1`.
2. **Cubic branch**: the `poly_kernel` module computes `|x[n]|^2` and forms the term `x[n]|x[n]|^2`; then `poly_branch` applies the complex coefficient `c3` and rescales the result to the accumulator format.

Because the cubic branch contains more internal stages than the linear branch, the design performs explicit temporal alignment of the linear branch before recomposition. The sum is not performed by an external complex adder in the main path; instead, it is implemented locally in `dpd_core` as registered accumulation with extended word length.

After accumulation, the result is sent to the `rounding` module, which is exclusively responsible for arithmetic rounding and scale conversion. Finally, the `saturator` module applies range limiting, registers the final output, and generates overflow signaling.

This separation of responsibilities is one of the most important architectural decisions of the work. By concentrating scale conversion in `rounding` and reserving `saturator` only for final saturation, the design simplifies numerical analysis and makes verification more objective.

### 4.3 Numerical Representation

The entire architecture was implemented in fixed-point arithmetic. At the external interface, input, output, and coefficients use Q1.15 format. Internally, word lengths are increased to preserve precision during polynomial term formation and final accumulation. The centralized numerical configuration was frozen in the `config.vh` file.

The main formats observed in the architecture are summarized below:

| Signal | Format |
|---|---|
| Complex input | Q1.15 |
| Complex coefficients | Q1.15 |
| `|x|^2` | Q3.30 |
| Cubic term `x|x|^2` | Q4.45 |
| Rescaled linear and cubic branches | Q3.30 |
| Accumulator | Q4.30 |
| Output after rounding | Q1.15 |
| Final output | Q1.15 |

This numerical policy highlights an important design choice: instead of prematurely truncating intermediate results, DPDnano-Lite preserves precision throughout the internal stages and postpones scale reduction to the semantically correct point in the flow. The benefit is lower accumulated error; the cost is a larger internal word length, still compatible with the Lite proposal.

### 4.4 Pipeline and Temporal Synchronization

The architecture is synchronous, single-clock-domain, and flow-oriented. There is explicit registration at the outputs of `complex_mult`, `poly_kernel`, `poly_branch`, in the accumulation stage of `dpd_core`, at the output of `rounding`, and at the final output of `saturator`. This organization results in a fixed latency of five cycles between acceptance of a valid sample and availability of the corresponding output (Bhasker and Chadha, 2009).

After the initial pipeline fill, the system accepts one new valid sample per clock cycle. In other words, absolute latency is not minimal, but sustained throughput is appropriate for continuous baseband processing. This is consistent with the project philosophy: prioritize predictability and practical realizability rather than maximum aggressiveness in frequency or parallelism.

## 5. RTL Implementation

### 5.1 Core Modules

The core modules of the validated datapath are:

1. `dpd_core`
2. `complex_mult`
3. `poly_kernel`
4. `poly_branch`
5. `rounding`
6. `saturator`

The `dpd_core` module defines the functional contract of the architecture, integrates the branches, performs temporal alignment, and implements registered accumulation. The `complex_mult` module materializes the complex linear gain. The `poly_kernel` module explicitly forms the nonlinear term `x|x|^2`. The `poly_branch` module applies the cubic coefficient and conforms the nonlinear branch to the accumulator format. The `rounding` module establishes the boundary between extended internal precision and final output format. The `saturator` module isolates saturation treatment as a final and monitorable phenomenon.

### 5.2 Auxiliary Modules and Scope of the Frozen Version

The modules `fixed_mult`, `complex_add`, `iq_delay`, `coeff_bank`, and `mult_generic` remain in the repository as support infrastructure, arithmetic library elements, evolutionary documentation, and a basis for future expansion. However, they do not compose the main functional flow used in the frozen validation campaign.

This distinction is important because it reinforces the scientific fidelity of the description. In academic architectures, repositories often preserve variants, auxiliary blocks, and evolutionary paths. Nevertheless, the technical analysis must clearly identify which elements actually participated in the tested system and which belong to the broader project ecosystem.

## 6. Experimental Results

### 6.1 Functional Validation: TC001 to TC010

The functional tests TC001 to TC010 covered reset behavior, null input, positive and negative linear regime, cubic branch activation, positive saturation, negative saturation, overflow flags, pipeline latency, and throughput benchmark.

Taken together, these tests confirmed that:

1. The architecture starts from a known state and does not produce spurious activity after reset.
2. A null input is preserved as a null output.
3. The linear path operates correctly for different signal polarities and values.
4. The cubic branch contributes functionally and observably to the total response.
5. The saturation policy is consistent at both positive and negative extremes.
6. Overflow signaling correctly tracks range-exceeding events.
7. The observed latency matches the designed pipeline organization.
8. The system sustains continuous sample delivery in long campaigns.

This set of evidence establishes the minimum behavioral correctness of the frozen architecture and forms the basis upon which the TMQ experiments can be interpreted.

### 6.2 Nominal and Numerical Characterization: TMQ001 to TMQ006

The TMQ001 to TMQ006 campaigns provided the central quantitative results for the evaluation of DPDnano-Lite.

In **TMQ001**, the architecture processed **131072 vectors**, with **100% delivery**, **5-cycle latency**, and **zero overflow events** under the adopted nominal configuration. This result indicates that, in a moderate regime, the system operates entirely within a safe region.

In **TMQ002**, with the cubic branch disabled, **512 out of 512 evaluated points passed**, **maximum absolute error was zero**, and **no overflow** occurred, confirming the fidelity of the linear regime.

In **TMQ003**, with significant cubic-branch activation, the observed values were `max_linear_abs = 12288`, `max_poly_abs = 3456`, and `max_output_abs = 15744`, with no overflow. The result shows that the cubic component is not merely nominal: it contributes measurably to the total output.

In **TMQ004**, dedicated to quantization error, the **maximum absolute error remained below 0.5 LSB**, with a centered distribution, which is consistent with a well-behaved rounding policy.

In **TMQ005**, in a complex scenario with active real and imaginary coefficients, the observed results were **maximum error of approximately 1.5 LSB per component**, **maximum magnitude error of about 1.57 LSB**, and **magnitude RMS error below 0.007%**. This demonstrates high numerical fidelity even under complex interaction between branches.

In **TMQ006**, temporal characterization confirmed `latency_min = 5`, `latency_max = 5`, and `latency_avg = 5`, with an observed throughput of approximately **0.99939 vectors per cycle**, which in practice corresponds to one valid sample delivered per cycle after pipeline fill.

### 6.3 Stability, Statistics, Symmetry, and Repeatability: TMQ007 to TMQ010

The TMQ007 to TMQ010 campaigns deepened the analysis of operational robustness.

In **TMQ007**, with **100000 samples**, all monitored fault indicators remained zero: `xz_errors`, `logical_nan_errors`, `glitch_errors`, `stall_errors`, and `oscillation_flags`. The maximum observed output repetition length was equal to 1, indicating the absence of stalling or artificial repetition.

In **TMQ008**, also with **100000 samples**, mean values close to zero, similar variances between I and Q, and balanced histograms were observed, suggesting the absence of macroscopic statistical bias and good global symmetry in complex processing.

In **TMQ009**, with **8192 pairs of symmetric samples**, the maximum absolute symmetry error was **1 LSB per component**, equivalent to about `3.05e-5` in real value. The result shows that the fixed-point implementation preserves the expected symmetry of the model with minimal error.

In **TMQ010**, dedicated to repeatability under stress, **1000 repetitions** of a sequence of **1024 samples** were performed, totaling **1024000 vectors**. The result was particularly strong: `mismatch_count = 0`, that is, **100% bit-exact repeatability**, even with **409000 saturated outputs** and an overflow rate close to **40%**. This is one of the most relevant results of the work, because it shows that frequent saturation does not imply erratic behavior; the system remains fully deterministic.

### 6.4 Coefficient Sensitivity and Operational Limits: TMQ011 to TMQ013

The TMQ011 to TMQ013 campaigns investigated the operational boundaries of the architecture.

In **TMQ011**, **4225 combinations of real coefficients** were evaluated, of which **3105** were classified as safe and **1120** as unsafe, resulting in **73.49% safe combinations** in the tested space. The result shows that the saturation-free operating region is broad, but not unrestricted.

In **TMQ012**, in the complex domain, **42 safe combinations** and **39 unsafe combinations** were observed, with a safety ratio of approximately **51.85%**. Compared to the real-coefficient case, the safe boundary becomes narrower, highlighting the influence of phasor geometry on operational margin.

In **TMQ013**, the system was subjected to increasing amplitude stress. The experiment identified **first saturation at level 41**, **first persistent saturation at level 44**, **last still-safe level equal to 40**, and **maximum safe amplitude of approximately 0.828125**, while the first saturation appeared at approximately **0.845703125**. The overall observed safety rate was **88.54%**. This result provides an objective operational threshold and distinguishes isolated saturation from persistent saturation, enriching the interpretation of system behavior.

## 7. Discussion

The obtained results allow DPDnano-Lite to be interpreted from three complementary perspectives.

The first is the **architectural perspective**. The choice of a low-order model structured into a linear branch and a cubic branch proved sufficient to produce a technically meaningful implementation without requiring an excessively large topology. The modularity of the flow, the separation between `rounding` and `saturator`, and the explicit temporal alignment between branches contributed to structural clarity and system verifiability.

The second is the **numerical perspective**. The decision to preserve extended internal precision and postpone scale conversion to the appropriate stage resulted in low and controlled errors. The performance observed in TMQ004 and TMQ005 indicates that the architectural simplification was not achieved at the expense of numerical degradation incompatible with practical use.

The third is the **temporal and operational perspective**. The fixed five-cycle latency, the sustained throughput close to one sample per cycle, the absence of spurious behavior in long campaigns, and the bit-exact repeatability under severe stress indicate that DPDnano-Lite is more than a logical prototype. It is an architecture with sufficiently predictable behavior to support both rigorous academic analysis and future experimental integration.

At the same time, the sensitivity and operational-limit tests make it clear that the architecture is not arbitrarily unlimited. Like any fixed-point system with finite dynamic range, it imposes real boundaries on admissible parametrization. Far from being a methodological weakness, this result strengthens the scientific value of the work, as it transforms the evaluation into an investigation of operational margin rather than merely a demonstration of nominal functionality.

## 8. Conclusion

This paper presented DPDnano-Lite, a compact RTL architecture for digital predistortion on small FPGA devices. The proposal was built from a deliberately lean architectural cut, based on one linear branch and one third-order cubic branch, implemented in Verilog-2001 with fully fixed-point arithmetic.

The experimental results show that the architecture:

1. Is functionally correct under its basic test campaign.
2. Has fixed five-cycle latency.
3. Sustains one valid sample per cycle after pipeline fill.
4. Exhibits controlled quantization error and high numerical fidelity.
5. Remains stable and deterministic in long campaigns and under saturation stress.
6. Has measurable and technically interpretable operational boundaries.

Therefore, DPDnano-Lite fulfills its central goal: demonstrating the feasibility of a compact, modular, verifiable digital predistortion architecture compatible with resource-constrained reconfigurable hardware.

Future work includes the incorporation of explicit memory, higher polynomial orders, more sophisticated internal parameterization, integration with adaptive coefficient-update flows, and validation in hardware-in-the-loop or laboratory experiments with a real power amplifier.

## Acknowledgments

The authors thank the advisor, the institution, and laboratory colleagues for the technical and academic support provided during the development of this work.

## References

BERGERON, Janick. *Writing Testbenches: Functional Verification of HDL Models*. 2nd ed. Boston: Kluwer Academic Publishers, 2000.

BHASKER, J.; CHADHA, Rakesh. *Static Timing Analysis for Nanometer Designs: A Practical Approach*. New York: Springer, 2009.

DING, Lei; ZHOU, Guo Tong; MORGAN, Dennis R.; MA, Zhengxiang; KENNEY, John S.; KIM, Jaehyeong; GIARDINA, Charles R. A robust digital baseband predistorter constructed using memory polynomials. *IEEE Transactions on Communications*, vol. 52, no. 1, pp. 159-165, 2004.

GILABERT, Pere L.; DING, Lei. Digital predistortion for power amplifiers. In: CHANG, Kai (ed.). *Encyclopedia of RF and Microwave Engineering*. Hoboken: Wiley, 2024.

LI, Wantao; MONTORO, Gabriel; GILABERT, Pere L. GPU versus FPGA implementation of a digital predistortion linearizer for wideband radiofrequency power amplifiers. *AEU - International Journal of Electronics and Communications*, vol. 174, 155040, 2024.

MORGAN, Dennis R.; MA, Zhengxiang; KENNEY, John S.; KIM, Jaehyeong; GIARDINA, Charles R. A generalized memory polynomial model for digital predistortion of RF power amplifiers. *IEEE Transactions on Signal Processing*, vol. 54, no. 10, pp. 3852-3860, 2006.

SIPEED. Tang Nano 4K. Sipeed Wiki. Available at: <https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-4K/Nano-4K.html>. Accessed on: Jul. 29, 2026.

ZHU, Anding. Behavioral modeling for digital predistortion of RF power amplifiers: from Volterra series to CPWL functions. In: *IEEE Topical Conference on Power Amplifiers for Wireless and Radio Applications (PAWR)*. Austin: IEEE, 2016.

## Submission Notes

1. Replace author names, institution, and e-mail fields.
2. Adapt the reference style to the final conference or journal template.
3. Keep the strongest experimental figures, especially TMQ002, TMQ003, TMQ004, TMQ010, TMQ011, TMQ012, and TMQ013.
4. If the target venue requires a short paper, Sections 2 and 5 can be condensed to keep the focus on architecture, results, and discussion.
