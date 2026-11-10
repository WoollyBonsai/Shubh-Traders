# Shubh Traders (शुभ ट्रेडर्स)
### Modern Point of Sale (POS), Inventory & Udhaar Ledger System for Windows 11 Desktop

A dedicated desktop billing and management application designed specifically for hardware and building material businesses (Cement, TMT Steel Bars, Sand, Bricks, Paints, and Aggregate).

---

## 🛠️ Tech Stack

* **Framework:** Flutter (Windows Desktop)
* **Database:** SQLite relational engine via `drift`
* **State Management:** Riverpod (`flutter_riverpod`)
* **Excel Export:** `excel` package combined with `file_picker` for direct file system save
* **PDF & Printing:** `pdf` and `printing` packages interfacing directly with Windows print dialogs
* **Local Storage:** `shared_preferences` for font scale multiplier, UI preferences, and shop headers
* **Visual Charts:** `fl_chart` for revenue analytics and payment distribution

---

## 🏗️ Architecture & Modules

### 1. Authentication System
* **Local SQLite Table:** `Users` (`id`, `username`, `password_hash`, `role`, `full_name`).
* Intercepts startup with a dedicated login card.
* SHA-256 PIN/Password hashing. Pre-seeded with:
  * **Admin:** `admin` / PIN: `1234`
  * **Staff:** `staff` / PIN: `1111`
* Staff and User management console to add employees or change credentials.
* Origin tracking: Authenticated user ID is recorded with every transaction.

### 2. Interactive Business Dashboard
* **KPI Metrics:** Today's gross sales, total pending Udhaar across all customers, active low-stock alerts, and catalog size.
* **Daily Revenue Analytics:** Interactive bar chart with 7-day and 14-day aggregated breakdowns.
* **Payment Mode Split:** Real-time breakdown of collections across Cash, UPI/Online, and Udhaar credit.
* **Critical Stock Alerts:** Immediate banner notification for items below safety thresholds with 1-click restock actions.

### 3. Inventory & Stock Management
* **Hierarchical Categorization:** Tables for grouping (Cement / सीमेंट, TMT Steel Bars / सरिया, Sand / रेत, etc.).
* **Item Specifications:** English & Hindi titles, Category, Unit (Bags, Kg, Trolley, Cft, Pcs), Purchase Price, Default Selling Price, Current Stock, and Alert Thresholds.
* **Atomic Transactions:** Stock deductions are guaranteed atomic upon sale checkout.
* **Quick Restock Modal:** Instant dialog to log incoming inventory and update purchase/selling prices.

### 4. Point of Sale (POS)
* **Two-Pane Desktop Interface:** Left-hand searchable catalog with category chips; right-hand interactive cart and checkout drawer.
* **Customer Capture & Autocomplete:** Search existing accounts or register walk-ins with phone numbers.
* **Live Udhaar Badge:** Warns cashier if selected customer has overdue balance.
* **Cart Adjustments:** Interactive quantity stepper (+ / -), item removal, and **in-place selling price override**.
* **Payment Modes:** `Cash` (नकद), `Online` (UPI/Bank), or `Udhaar` (उधार).
* **Udhaar Credit Routing:** Credit sales automatically adjust the customer's outstanding balance in SQLite within the same database transaction.

### 5. Ledger & Udhaar Book
* **Sales Transaction History:** Comprehensive filterable ledger with invoice numbers, timestamps, customer details, payment methods, and staff names.
* **Udhaar Book:** Outstanding debts interface with individual customer statements, debtor counts, and payment intake dialogs to log incoming debt clearances.
* **Native Excel Export (`.xlsx`):** Multi-sheet workbook generator (Sales Report, Udhaar Debtors, Inventory Valuation) with Windows file save dialog.

### 6. Bill Generation & Windows Printing
* Standardized receipts in **A4 Tax Invoice** or **80mm Thermal Receipt** layouts.
* Formatted with "Shubh Traders" bilingual header, Date, Time, Invoice number, Cashier name, Customer details, itemized matrix, payment mode, and total debt balance.
* Native Windows print dialog integration via `Printing.layoutPdf`.

### 7. Bilingual UI/UX & Accessibility
* **Dual Language Visibility:** Custom `DualText` widget displaying English and Hindi (e.g. `UltraTech Cement / अल्ट्राटेक सीमेंट`) stacked vertically or inline globally.
* **Dynamic Font Scaling:** Slider in Settings adjusts global `fontSizeMultiplier` (0.8x to 1.4x) with real-time UI previews.

---

## 🚀 Running the Application on Windows

### Prerequisites
1. Windows 11 (or 10) 64-bit.
2. Visual Studio 2022 / Community with **Desktop development with C++** workload.
3. Flutter SDK (installed at `D:\Work\flutter` and added to `PATH`).

### Commands

To run directly on Windows desktop:
```powershell
flutter run -d windows
```

To compile a release Windows executable (`.exe`):
```powershell
flutter build windows
```
The executable will be located in:
`build\windows\x64\runner\Release\shubh_traders.exe`
