from bs4 import BeautifulSoup
import requests, csv, datetime, os, smtplib

URL = "https://www.amazon.com/dp/B0CQ1HP3RX/"   # JBL товар
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    "Accept-Language": "en-US,en;q=0.9"
}
TARGET_PRICE = 50
CSV_NAME = "jbl_price_tracker.csv"

def check_price():
    r = requests.get(URL, headers=HEADERS, timeout=30)
    html = BeautifulSoup(r.content, "lxml")
    title = html.select_one("#productTitle").get_text(strip=True)
    try:
        whole = html.select_one(".a-price-whole").get_text().replace(",", "")
        frac  = html.select_one(".a-price-fraction").get_text()
        price = float(whole) + float(frac)/100
    except Exception:
        price = None
    return title, price, datetime.date.today(), URL

def save_row(row):
    file_exists = os.path.exists(CSV_NAME)
    with open(CSV_NAME, "a", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        if not file_exists:
            w.writerow(["Title","Price","Date","URL"])
        w.writerow(row)

def send_email_if_needed(title, price):
    if price is None or price >= TARGET_PRICE:
        return
    email = os.environ.get("MY_EMAIL")
    pwd = os.environ.get("MY_PASSWORD")
    if not email or not pwd:
        return
    msg = f"Subject:JBL Price Alert!\n\n{title} is now ${price}\n{URL}"
    with smtplib.SMTP("smtp.gmail.com") as s:
        s.starttls()
        s.login(email, pwd)
        s.sendmail(email, email, msg.encode("utf-8"))

if __name__ == "__main__":
    row = check_price()
    save_row(row)
    send_email_if_needed(row[0], row[1])
