import os
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

# 1) Load Data ===
# If your file has a different name, change it here
df = pd.read_csv('SampleSuperstore.csv', encoding ='latin1')

# 2) Data Preprocessing ===
df = df.drop_duplicates()
# Convert Order Date to datetime
df['Order Date'] = pd.to_datetime(df['Order Date'], errors='coerce', dayfirst=False)
df = df.dropna(subset=['Order Date'])
df['YearMonth'] = df['Order Date'].dt.to_period('M').astype(str)

# 3) KPI Calculation ===
total_sales = df['Sales'].sum()
total_profit = df['Profit'].sum()
total_orders = df['Order ID'].nunique()
avg_discount = df['Discount'].mean()
aov = total_sales / total_orders  # Average Order Value
profit_margin = total_profit / total_sales  # Profit Margin

print(f"Total Sales: ${total_sales:,.2f}")
print(f"Total Profit: ${total_profit:,.2f}")
print(f"Total Orders: {total_orders:,}")
print(f"Average Discount: {avg_discount:.2%}")
print(f"AOV (Avg Order Value): ${aov:,.2f}")
print(f"Profit Margin: {profit_margin:.2%}")

# 4) Aggregations for Charts ===
sales_by_region  = df.groupby('Region')['Sales'].sum().sort_values(ascending=False)
profit_by_cat    = df.groupby('Category')['Profit'].sum().sort_values(ascending=False)
sales_trend      = df.groupby('YearMonth')['Sales'].sum().reset_index()
# Pivot table for heatmap: Profit by (Region x Category)
pivot_profit = df.pivot_table(index='Region', columns='Category', values='Profit', aggfunc='sum').fillna(0)

# 5) Create folder for images ===
os.makedirs('images', exist_ok=True)

# 6) Chart 1: Sales by Region (Bar) ===
plt.figure(figsize=(8,5))
sales_by_region.plot(kind='bar')
plt.title('Sales by Region')
plt.xlabel('Region'); plt.ylabel('Total Sales ($)')
plt.tight_layout(); plt.savefig('images/01_sales_by_region.png', dpi=150); plt.show()

# 7) Chart 2: Profit by Category (Bar) ===
plt.figure(figsize=(8,5))
profit_by_cat.plot(kind='bar')
plt.title('Profit by Category')
plt.xlabel('Category'); plt.ylabel('Total Profit ($)')
plt.tight_layout(); plt.savefig('images/02_profit_by_category.png', dpi=150); plt.show()

# 8) Chart 3: Monthly Sales Trend (Line) ===
sales_trend['YearMonth'] = pd.to_datetime(sales_trend['YearMonth'])
plt.figure(figsize=(9,5))
plt.plot(sales_trend['YearMonth'], sales_trend['Sales'], marker='o')
plt.title('Monthly Sales Trend')
plt.xlabel('Month'); plt.ylabel('Sales ($)'); plt.grid(True)
ax = plt.gca()
ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m'))
ax.xaxis.set_major_locator(mdates.MonthLocator(interval=2))
plt.xticks(rotation=45)
plt.tight_layout(); plt.savefig('images/03_sales_trend.png', dpi=150); plt.show()

#  9) Chart 4: Profit Heatmap (Region x Category)
plt.figure(figsize=(7,5))
plt.imshow(pivot_profit.values, aspect='auto')
plt.title('Profit Heatmap (Region x Category)')
plt.xlabel('Category'); plt.ylabel('Region')
plt.xticks(ticks=range(len(pivot_profit.columns)), labels=pivot_profit.columns, rotation=45)
plt.yticks(ticks=range(len(pivot_profit.index)), labels=pivot_profit.index)
plt.colorbar(label='Profit ($)')
plt.tight_layout(); plt.savefig('images/04_profit_heatmap.png', dpi=150); plt.show()
