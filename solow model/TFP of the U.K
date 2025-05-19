!pip install fredapi
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from fredapi import Fred

# FRED APIキー（適切なものに差し替えてください）
fred = Fred(api_key='46b4fbabbfe7ae0e8ca50e2ab83e48e2')

# FREDシリーズID（UK）
series_codes = {
    'y_pc': 'PCAGDPGBA646NWDB',        # Real GDP per capita (constant USD)
    'K': 'RKNANPGBA666NRUG',          # Gross capital formation (index)
    'POP': 'POPUKA'        # Total population
}

# データ取得
data = {}
for var, code in series_codes.items():
    series = fred.get_series(code)
    if series.index.freq is None:
        series = series.resample('A').mean()  # 年次変換
    data[var] = series

# データ結合
df = pd.DataFrame(data).dropna()

# 一人当たり資本ストック（proxy）
df['k_pc'] = df['K'] / df['POP']

# ログ変換
df['log_y_pc'] = np.log(df['y_pc'])
df['log_k_pc'] = np.log(df['k_pc'])

# 資本シェア
alpha = 0.42

# TFP推定
df['log_A'] = df['log_y_pc'] - alpha * df['log_k_pc']

# 成長率（対数差分）
df['g_y'] = df['log_y_pc'].diff()
df['g_k'] = df['log_k_pc'].diff()
df['g_A'] = df['log_A'].diff()

df['tfp_contrib'] = df['g_A']
df['capital_contrib'] = alpha * df['g_k']

# 整理
result = df[['g_y', 'g_A', 'g_k', 'tfp_contrib', 'capital_contrib']].dropna()
result.columns = ['GDP per capita Growth', 'TFP Growth', 'Capital Growth', 'TFP Contribution', 'Capital Contribution']

# 可視化
plt.figure(figsize=(12, 6))
plt.plot(result.index, result['GDP per capita Growth'], label='GDP per capita Growth')
plt.plot(result.index, result['TFP Growth'], label='TFP Growth')
plt.plot(result.index, result['Capital Growth'], label='Capital Deepening')
plt.title('UK Solow Growth Accounting (per capita, 1960–2000)')
plt.xlabel('Year')
plt.ylabel('Growth Rate (log difference)')
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()