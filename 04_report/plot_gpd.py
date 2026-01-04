import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import genpareto

# Parameters
theta = 0          # location
sigma = 214.476    # scale
k = 0.348238       # shape

# Generate x values
# We go from theta to the 99th percentile to capture the relevant part of the tail
# Since k > 0, the domain is x >= theta
x_max = genpareto.ppf(0.99, c=k, loc=theta, scale=sigma)
# x_max = genpareto.ppf(0.50, c=k, loc=theta, scale=sigma)
x = np.linspace(theta, x_max, 1000)

# Calculate the PDF
pdf_values = genpareto.pdf(x, c=k, loc=theta, scale=sigma)

# Custom values given in the paper
x_custom = np.arange(15)
y_custom = [0.00536,
            0.00047,
            0.17820,
            0.09239,
            0.00018,
            0.02740,
            0.00065,
            0.00606,
            0.00023,
            0.00837,
            0.00837,
            0.08989,
            0.00092,
            0.00326,
            0.01980]

# Plotting
plt.figure(figsize=(10, 6))
plt.plot(x, pdf_values, label=f'GPD ($theta={theta}, sigma={sigma}, k={k}$)')
plt.scatter(x_custom, y_custom, color='red', label='Custom values (0-14)', zorder=5, s=6)
plt.title(r'Value-Size Distribution (Generalized Pareto)')
plt.xlabel(r'$x$')
plt.ylabel(r'Density $f(x)$')
plt.grid(True, alpha=0.3)
plt.legend()
plt.show()
