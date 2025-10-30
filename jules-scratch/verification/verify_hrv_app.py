from playwright.sync_api import sync_playwright

def handle_console(msg):
    print(f"Browser console: {msg.text}")

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()
    page.on("console", handle_console)
    page.goto("http://127.0.0.1:5000/")
    page.set_input_files('input#hr-upload', 'MyHRV_Web_App/frontend/test_hr_data.txt')
    page.set_input_files('input#ecg-upload', 'MyHRV_Web_App/frontend/test_ecg_data.txt')
    page.click('button#analyze-button')
    page.wait_for_selector('#report-container h2', timeout=60000)
    page.screenshot(path='jules-scratch/verification/verification.png')
    browser.close()
