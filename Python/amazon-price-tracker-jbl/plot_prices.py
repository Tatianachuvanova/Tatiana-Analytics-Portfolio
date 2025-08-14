import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("jbl_price_tracker.csv")
df["Date"] = pd.to_datetime(df["Date"])
df = df.dropna(subset=["Price"])
plt.plot(df["Date"], df["Price"], marker="o")
plt.title("JBL Headphones Price History")
plt.xlabel("Date")
plt.ylabel("Price ($)")
plt.grid(True)
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()
