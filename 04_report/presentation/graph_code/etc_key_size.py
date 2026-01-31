import numpy as np
import scipy.stats as stats
import matplotlib.pyplot as plt

# Parameters from paper for ETC key size
mu = 30.7984      # location (μ)
sigma = 8.20449   # scale (σ)
k = 0.078688      # shape (k or ξ)

# Scipy uses different sign for k
c = -k

# Define the GEV distribution
gev_dist = stats.genextreme(c, loc=mu, scale=sigma)

# Generate points for the continuous Probability density function curve
x = np.linspace(gev_dist.ppf(0.001), gev_dist.ppf(0.999), 1000)
pdf = gev_dist.pdf(x)

# Visualization
plt.figure(figsize=(12, 7))
plt.style.use('bmh') # A clean style suitable for terminal/tiling WM users

# Plot the continuous PDF
plt.plot(x, pdf, 'r-', lw=2.5)

# Plot the histogram of simulated discrete key sizes
# plt.hist(samples_u32, bins=range(min(samples_u32), max(samples_u32) + 2), 
#          density=True, alpha=0.6, color='#4c72b0', edgecolor='none', 
#          label='Simulated Key Sizes (u32)')

# plt.title('Distribution of Generated Key Sizes')
plt.xlabel('Key Length (bytes)')
plt.ylabel('Probability Density')
plt.legend()
plt.grid(True, which='both', linestyle='--', alpha=0.7)

# Save or show
plt.savefig('etc_key_size.png')
plt.show()
