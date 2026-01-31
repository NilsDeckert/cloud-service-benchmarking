import numpy as np
import scipy.stats as stats
import matplotlib.pyplot as plt

# --- Parameters ---
discrete_probs = [
    0.00536, 0.00047, 0.17820, 0.09239, 0.00018,
    0.02740, 0.00065, 0.00606, 0.00023, 0.00837,
    0.00837, 0.08989, 0.00092, 0.00326, 0.01980
]
gpd_sigma = 214.476
gpd_k = 0.348238
gpd_loc = 15.0

# --- Setup Distributions ---
# 1. Discrete Part
x_discrete = np.arange(len(discrete_probs))
prob_discrete_total = sum(discrete_probs)

# 2. Continuous Tail (GPD)
# The tail occurs with probability (1 - sum(discrete_probs))
prob_tail_total = 1.0 - prob_discrete_total

# Scipy's genpareto uses 'c' for the shape parameter k
tail_dist = stats.genpareto(c=gpd_k, loc=gpd_loc, scale=gpd_sigma)

# Generate points for the tail curve
x_tail = np.linspace(gpd_loc, 1000, 5000)
# Scale the PDF by the probability of falling into the tail
y_tail = tail_dist.pdf(x_tail) * prob_tail_total 

# --- Plotting ---
plt.figure(figsize=(12, 7))
plt.style.use('bmh') # Clean style for Arch/tiling setups

# Plot Discrete Bars
plt.bar(x_discrete, discrete_probs, color='#4c72b0', alpha=0.8, 
        label='Discrete Probabilities (0-14)')

# Plot Tail Curve
plt.plot(x_tail, y_tail, color='#c44e52', linewidth=2.5, 
         label=f'Tail GPD PDF)')

# Formatting
plt.yscale('log') # Log scale is crucial here due to magnitude differences
# plt.title(r'Hybrid Distribution: Discrete (0-14) + GPD Tail ($\xi \approx 0.35$)')
plt.xlabel('Value Length')
plt.ylabel('Probability / Density (Log Scale)')
plt.legend()
plt.grid(True, which="both", ls="-", alpha=0.3)

# Add text annotation for the transition
plt.axvline(14.5, color='black', linestyle=':', alpha=0.5)
plt.text(16, 1e-2, "Transition to GPD \u2192", verticalalignment='center')

plt.tight_layout()
plt.savefig('etc_value_size.png')
plt.show()
