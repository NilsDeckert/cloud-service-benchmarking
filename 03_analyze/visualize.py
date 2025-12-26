#!/bin/python3
# This script was written by gemini

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os

def load_data(file_path):
    """Loads CSV and adds Client column based on id resets."""
    # Handle missing extension
    if not os.path.exists(file_path) and os.path.exists(file_path + ".csv"):
        file_path += ".csv"
        
    try:
        print(f"Reading file: {file_path}")
        df = pd.read_csv(file_path)
        
        # Verify required columns
        required_cols = {'id', 'duration'}
        if not required_cols.issubset(df.columns):
            # Check for capitalization issues
            df.columns = df.columns.str.lower()
            if not required_cols.issubset(df.columns):
                 print(f"Error: CSV must contain 'id' and 'duration' columns. Found: {df.columns.tolist()}")
                 return None

        # Derive Client ID
        # This writes to a 'client' row, how often we've seen id == 0
        df['Client'] = (df['id'] == 0).cumsum()
        
        print(f"Loaded {len(df)} rows, found {df['Client'].nunique()} clients.")
        return df
    except Exception as e:
        print(f"Error loading file: {e}")
        return None

def merge_to_n(group, n_out):
    """Divides a group into n_out segments and sums the duration."""
    # Create an array of indices [0, 1, 2, 3...] for the group
    size = len(group)
    # This math creates a bin ID (0 to n_out-1) for each row
    bin_ids = np.arange(size) * n_out // size
    
    # Group by these bin IDs and sum
    return group.groupby(bin_ids)['duration'].sum()

def consolidate_to_long(df, n_bins):
    # Step A: Create a binning column for each client
    # This assigns 0 to the first half of rows and 1 to the second half (for 2 bins)
    df['bin'] = df.groupby('Client').cumcount()
    df['bin'] = df.groupby('Client')['bin'].transform(lambda x: (x * n_bins // len(x)))

    # Step B: Group by Client and Bin, then aggregate
    # We sum duration and usually take the 'first' id to represent the bin
    long_df = df.groupby(['Client', 'bin']).agg({
        'id': 'first',
        'duration': 'sum'
    }).reset_index()

    # Step C: Reorder and clean up columns to match your request
    return long_df[['id', 'duration', 'Client']]

def visualize_latency_box(file_path):
    df = load_data(file_path)
    if df is None: return

    # Set a clean visual style
    sns.set_theme(style="whitegrid")
    
    fig, ax1 = plt.subplots(figsize=(12, 12))

    # Box Plot grouped by Client
    sns.boxplot(x='Client', y='duration', data=df, ax=ax1, palette="muted")
    ax1.set_title('Latency Distribution (Box Plot) by Client', fontsize=14)
    ax1.set_xlabel('Client ID', fontsize=12)
    ax1.set_ylabel('Duration (μs)', fontsize=12)

    plt.tight_layout()
    
    # Save the output
    output_file = 'latency_analysis.png'
    plt.savefig(output_file)
    print(f"Visualization saved to {output_file}")

def visualize_latency_violin(file_path):
    df = load_data(file_path)
    if df is None: return

    # Set a clean visual style
    sns.set_theme(style="whitegrid")
    
    _, ax = plt.subplots(figsize=(12, 12))

    # Violin Plot - Shows the density of the data
    # Grouped by Client as requested
    sns.violinplot(x='Client', y='duration', data=df, ax=ax, inner="quart", palette="muted")
    ax.set_title('Latency Density (Violin Plot) by Client', fontsize=14)
    ax.set_xlabel('Client ID', fontsize=12)
    ax.set_ylabel('Duration (μs)', fontsize=12)

    # Save the output
    output_file = 'latency_violin.png'
    plt.savefig(output_file)
    print(f"Visualization saved to {output_file}")

def visualize_latency_by_client_and_subsection(file_path):
    df = load_data(file_path)
    if df is None: return

    # If the df contains more than 10 measurements per client, group them
    if df['id'].nunique() > 10:
        df = consolidate_to_long(df, 10)

    # Convert duration to s
    df['duration'] = df['duration'] / 1_000_000

    # Set theme
    sns.set_theme(style="whitegrid")
    
    # Create a figure with a larger width
    fig, ax = plt.subplots(figsize=(16, 8))

    # Create Grouped Bar Chart
    # X axis = Client, Hue = Subsection (id)
    # This groups measurements for each client
    sns.barplot(x='Client', y='duration', hue='id', data=df, ax=ax, palette="viridis")

    ax.set_title('Latency per Subsection for each Client', fontsize=16)
    ax.set_xlabel('Client ID', fontsize=14)
    ax.set_ylabel('Duration (s)', fontsize=14)
    
    # Move legend to the side
    ax.legend(title='Subsection (id)', bbox_to_anchor=(1.05, 1), loc='upper left')

    plt.tight_layout()
    output_file = 'latency_grouped_bars.png'
    plt.savefig(output_file)
    print(f"Grouped bar chart saved as '{output_file}'")

import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Visualize latency data from CSV.')
    parser.add_argument('file_path', help='Path to the input CSV file', default="benchmark/target/2025-12-26.csv", nargs="?")
    args = parser.parse_args()

    print(args)

    visualize_latency_box(args.file_path)
    visualize_latency_violin(args.file_path)
    visualize_latency_by_client_and_subsection(args.file_path)
