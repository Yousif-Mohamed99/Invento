# ⚡ Backend Quick Start (Copy-Paste Ready)

## 5-Minute Setup

### 1️⃣ Get Credentials

**Braintree Sandbox:**
https://www.braintreepayments.com/sandbox → Sign up → Get Merchant ID, Public Key, Private Key

**Firebase:**
Firebase Console → Your Project → Project Settings → Service Accounts → Generate Key → Copy JSON

### 2️⃣ Create Backend Config

```bash
cd backend
cp .env.example .env
```

Edit `backend/.env` with your credentials:

```env
NODE_ENV=development
PORT=3000

BRAINTREE_ENV=Sandbox
BRAINTREE_MERCHANT_ID=paste_merchant_id_here
BRAINTREE_PUBLIC_KEY=paste_public_key_here
BRAINTREE_PRIVATE_KEY=paste_private_key_here

FIREBASE_ADMIN_SDK='paste_entire_json_here'
FIREBASE_DATABASE_URL=https://your-project.firebaseio.com

ALLOWED_ORIGINS=http://localhost:3000,http://10.0.2.2:3000
SUBSCRIPTION_VALIDITY_DAYS=30
```

### 3️⃣ Install & Run

```bash
cd backend
npm install
npm run dev
```

**Expected output:**

```
Server running on http://localhost:3000 ✓
```

### 4️⃣ Test Backend

```bash
curl http://localhost:3000/health
```

Should return: `{"status":"OK","timestamp":"..."}`

### 5️⃣ Test in Flutter App

1. `flutter run`
2. Go to Subscription Paywall
3. Select any plan
4. Click "ادفع الآن" (Pay Now)
5. Use test card: **4111 1111 1111 1111**
6. Complete payment
7. You should see success! ✅

---

## Braintree Test Cards

```
Visa:       4111 1111 1111 1111
Mastercard: 5555 5555 5555 4444
Declined:   2000 0000 0000 0002
Expiry:     Any future date
CVV:        Any 3 digits
```

---

## API Endpoints

```
GET    /api/payments/client-token
POST   /api/payments/confirm
POST   /api/payments/process
GET    /api/payments/transaction/:id
POST   /api/payments/void/:id
GET    /health
```

---

## Verify Setup

```bash
# Backend running?
curl http://localhost:3000/health

# Can get client token?
curl http://localhost:3000/api/payments/client-token

# Check logs
npm run dev  # Logs in terminal
```

---

## Android Emulator Note

If testing on Android Emulator, the URL `http://10.0.2.2:3000` accesses your machine's localhost. ✓ Already configured!

---

## Firebase Check

After payment succeeds:

- Firebase Console
- Collection: `merchants`
- Find your user
- Should see: `isSubscribed: true, plan: "..."` ✅

---

## Troubleshooting

| Issue                 | Fix                               |
| --------------------- | --------------------------------- |
| Backend won't start   | Check .env exists with all fields |
| CORS error            | Verify ALLOWED_ORIGINS in .env    |
| Can't connect         | Is backend running? `npm run dev` |
| Payment declined      | Use correct test card above       |
| Firebase not updating | Check service account permissions |

---

## Infrastructure at a Glance

```
Flutter App ← → Backend (Node.js) ← → Braintree
                    ↓
                 Firebase
```

---

## Production Deployment

When ready:

1. Get Braintree production credentials
2. Deploy backend (Firebase Cloud Run, Heroku, AWS)
3. Update Flutter URLs to production backend
4. Test with real test card

See `backend/README.md` for deployment options.

---

## Files Reference

| File                     | Purpose                                |
| ------------------------ | -------------------------------------- |
| `BACKEND_SETUP.md`       | Detailed setup guide                   |
| `BACKEND_INTEGRATION.md` | Architecture details                   |
| `COMPLETE_SUMMARY.md`    | Full overview                          |
| `backend/README.md`      | Complete API docs                      |
| `backend/server.js`      | Backend code                           |
| `backend/.env`           | Your config (create from .env.example) |

---

## Done! ✅

Your payment backend is complete and ready to use. You're 5 minutes away from testing it!

💡 **Next**: Get credentials and create `backend/.env` file.
