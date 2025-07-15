# JitsuFlow API ドキュメント

## 概要

JitsuFlow APIは、ブラジリアン柔術の道場管理、予約システム、ショップ、レンタルなどの機能を提供するRESTful APIです。

**ベースURL**: `https://jitsuflow-worker.yukihamada.workers.dev/api`

## 認証

ほとんどのエンドポイントは認証が必要です。認証には以下のヘッダーを含める必要があります：

```
Authorization: Bearer YOUR_AUTH_TOKEN
```

## エンドポイント一覧

### 1. ヘルスチェック

**エンドポイント**: `GET /api/health`  
**認証**: 不要  
**説明**: APIの稼働状況を確認

**レスポンス例**:
```json
{
  "status": "healthy",
  "timestamp": "2025-07-13T12:44:12.776Z",
  "service": "JitsuFlow API"
}
```

### 2. ユーザー管理

#### 2.1 ユーザー登録

**エンドポイント**: `POST /api/users/register`  
**認証**: 不要  
**説明**: 新規ユーザーを登録

**リクエストボディ**:
```json
{
  "email": "user@example.com",
  "password": "securepassword",
  "name": "山田太郎",
  "phone": "090-1234-5678"
}
```

**レスポンス例**:
```json
{
  "message": "Registration successful",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "山田太郎",
    "phone": "090-1234-5678",
    "role": "user",
    "created_at": "2025-07-13T10:00:00Z"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### 2.2 ログイン

**エンドポイント**: `POST /api/users/login`  
**認証**: 不要  
**説明**: ユーザーログイン

**リクエストボディ**:
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**レスポンス例**:
```json
{
  "message": "Login successful",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "山田太郎",
    "role": "user"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 3. 道場管理

#### 3.1 道場一覧取得

**エンドポイント**: `GET /api/dojos`  
**認証**: 必要  
**説明**: 登録されている道場の一覧を取得

**レスポンス例**:
```json
{
  "dojos": [
    {
      "id": 1,
      "name": "YAWARA JIU-JITSU ACADEMY",
      "address": "東京都渋谷区神宮前1-8-10 The Ice Cubes 8-9F",
      "instructor": "Ryozo Murata (村田良蔵)",
      "pricing_info": "なでしこプラン¥12,000/月、Yawara-8プラン¥22,000/月、フルタイムプラン¥33,000/月"
    },
    {
      "id": 2,
      "name": "Over Limit Sapporo",
      "address": "北海道札幌市中央区南4条西1丁目15-2 栗林ビル3F",
      "instructor": "Ryozo Murata",
      "pricing_info": "フルタイム¥12,000/月、マンスリー5¥10,000/月、レディース&キッズ¥8,000/月"
    }
  ]
}
```

### 4. 予約管理

#### 4.1 予約作成

**エンドポイント**: `POST /api/dojo/bookings`  
**認証**: 必要  
**説明**: 新規予約を作成

**リクエストボディ**:
```json
{
  "dojo_id": 1,
  "class_type": "ベーシッククラス",
  "booking_date": "2025-07-15",
  "booking_time": "19:00"
}
```

**レスポンス例**:
```json
{
  "booking": {
    "id": 123,
    "user_id": 1,
    "dojo_id": 1,
    "class_type": "ベーシッククラス",
    "booking_date": "2025-07-15",
    "booking_time": "19:00",
    "status": "confirmed",
    "created_at": "2025-07-13T10:00:00Z"
  }
}
```

#### 4.2 予約一覧取得

**エンドポイント**: `GET /api/dojo/bookings`  
**認証**: 必要  
**説明**: ユーザーの予約一覧を取得

**レスポンス例**:
```json
{
  "bookings": [
    {
      "id": 123,
      "dojo_id": 1,
      "class_type": "ベーシッククラス",
      "booking_date": "2025-07-15",
      "booking_time": "19:00",
      "status": "confirmed"
    }
  ]
}
```

### 5. 商品管理

#### 5.1 商品一覧取得

**エンドポイント**: `GET /api/products`  
**認証**: 必要  
**説明**: 商品一覧を取得

**クエリパラメータ**:
- `category`: カテゴリーでフィルタ（gi, belt, protector, apparel, equipment, supplement, accessories）
- `limit`: 取得件数（デフォルト: 20）
- `offset`: オフセット（デフォルト: 0）

**レスポンス例**:
```json
{
  "products": [
    {
      "id": 1,
      "name": "YAWARA プレミアム道着",
      "description": "最高級コットン100%使用の高品質道着。試合規定対応。",
      "price": 18000,
      "category": "gi",
      "image_url": "https://example.com/gi1.jpg",
      "stock_quantity": 12,
      "is_active": true,
      "size": "A2",
      "color": "white",
      "attributes": {
        "material": "コットン100%",
        "weight": "550gsm",
        "certification": "IBJJF認定"
      }
    }
  ]
}
```

#### 5.2 カートに追加

**エンドポイント**: `POST /api/cart/add`  
**認証**: 必要  
**説明**: 商品をカートに追加

**リクエストボディ**:
```json
{
  "product_id": 1,
  "quantity": 2
}
```

**レスポンス例**:
```json
{
  "message": "Added to cart"
}
```

#### 5.3 カート取得

**エンドポイント**: `GET /api/cart`  
**認証**: 必要  
**説明**: ユーザーのカート内容を取得

**レスポンス例**:
```json
{
  "items": [
    {
      "product": {
        "id": 1,
        "name": "YAWARA プレミアム道着",
        "price": 18000,
        "category": "gi",
        "image_url": "https://example.com/gi1.jpg"
      },
      "quantity": 2
    }
  ]
}
```

### 6. レンタル管理

#### 6.1 レンタル品一覧取得

**エンドポイント**: `GET /api/dojo-mode/:dojoId/rentals`  
**認証**: 必要  
**説明**: 道場のレンタル品一覧を取得

**レスポンス例**:
```json
{
  "rentals": [
    {
      "id": 1,
      "item_type": "gi",
      "item_name": "道着（白帯用）",
      "size": "A2",
      "color": "white",
      "condition": "good",
      "dojo_id": 1,
      "total_quantity": 5,
      "available_quantity": 3,
      "rental_price": 1000,
      "deposit_amount": 5000,
      "status": "available"
    }
  ]
}
```

#### 6.2 レンタル開始

**エンドポイント**: `POST /api/rentals/:rentalId/rent`  
**認証**: 必要  
**説明**: レンタルを開始

**リクエストボディ**:
```json
{
  "user_id": 1,
  "return_due_date": "2025-07-20T23:59:59Z"
}
```

**レスポンス例**:
```json
{
  "transaction": {
    "id": 456,
    "rental_id": 1,
    "user_id": 1,
    "rental_date": "2025-07-13T10:00:00Z",
    "return_due_date": "2025-07-20T23:59:59Z",
    "status": "active"
  }
}
```

### 7. ビデオコンテンツ

#### 7.1 ビデオ一覧取得

**エンドポイント**: `GET /api/videos`  
**認証**: 必要  
**説明**: ビデオコンテンツ一覧を取得

**クエリパラメータ**:
- `premium`: プレミアムコンテンツのみ表示（true/false）

**レスポンス例**:
```json
{
  "videos": [
    {
      "id": "video-1",
      "title": "【初心者必見】クローズドガードの基本",
      "description": "柔術の基本中の基本、クローズドガードの正しいポジションと基本的な動きを解説。",
      "is_premium": false,
      "category": "basics",
      "upload_url": "https://example.com/basic-closed-guard.mp4",
      "thumbnail_url": "https://example.com/thumb.jpg",
      "duration": 780,
      "views": 2453,
      "status": "published"
    }
  ]
}
```

### 8. 支払い管理

#### 8.1 サブスクリプション作成

**エンドポイント**: `POST /api/payments/create-subscription`  
**認証**: 必要  
**説明**: プレミアムサブスクリプションを作成

**リクエストボディ**:
```json
{
  "price_id": "price_monthly_premium",
  "payment_method_id": "pm_card_visa"
}
```

**レスポンス例**:
```json
{
  "subscription": {
    "id": "sub_1234567890",
    "status": "active",
    "current_period_end": "2025-08-13T10:00:00Z"
  }
}
```

## エラーレスポンス

すべてのエラーは以下の形式で返されます：

```json
{
  "error": "エラーの概要",
  "message": "詳細なエラーメッセージ"
}
```

### 一般的なHTTPステータスコード

- `200 OK`: リクエスト成功
- `201 Created`: リソース作成成功
- `400 Bad Request`: 不正なリクエスト
- `401 Unauthorized`: 認証が必要
- `403 Forbidden`: アクセス権限なし
- `404 Not Found`: リソースが見つからない
- `500 Internal Server Error`: サーバーエラー

## レート制限

APIにはレート制限が設定されています：
- 認証済みユーザー: 1時間あたり1000リクエスト
- 未認証ユーザー: 1時間あたり100リクエスト

レート制限の状態は以下のヘッダーで確認できます：
- `X-RateLimit-Limit`: 制限値
- `X-RateLimit-Remaining`: 残りリクエスト数
- `X-RateLimit-Reset`: リセット時刻（ISO 8601形式）

## デモアカウント

テスト用のデモアカウント：
- メール: `user@jitsuflow.app`
- パスワード: `demo123`

管理者デモアカウント：
- メール: `admin@jitsuflow.app`
- パスワード: `admin123`