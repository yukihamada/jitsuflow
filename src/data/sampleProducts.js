/**
 * サンプル商品データ
 * JitsuFlowショップ用の初期商品データ
 */

export const sampleProducts = [
  // 道着（Gi）
  {
    name: 'YAWARA プレミアム道着',
    description: '最高級コットン100%使用の高品質道着。試合規定対応。耐久性と快適性を両立。',
    price: 18000,
    category: 'gi',
    image_url: 'https://images.unsplash.com/photo-1604009506606-fd4989d50e6d?w=800',
    stock_quantity: 12,
    is_active: true,
    size: 'A2',
    color: 'white',
    attributes: JSON.stringify({
      material: 'コットン100%',
      weight: '550gsm',
      certification: 'IBJJF認定'
    })
  },
  {
    name: 'プレミアム道着（紺色）',
    description: '試合用紺色道着。IBJJF認定済み。最高品質の素材を使用。',
    price: 22000,
    category: 'gi',
    image_url: 'https://images.unsplash.com/photo-1604009506606-fd4989d50e6d?w=800',
    stock_quantity: 8,
    is_active: true,
    size: 'A3',
    color: 'navy',
    attributes: JSON.stringify({
      material: 'コットン100%',
      weight: '550gsm',
      certification: 'IBJJF認定'
    })
  },
  {
    name: '軽量道着（夏用）',
    description: '通気性に優れた軽量道着。暑い季節のトレーニングに最適。',
    price: 15000,
    category: 'gi',
    image_url: 'https://images.unsplash.com/photo-1604009506606-fd4989d50e6d?w=800',
    stock_quantity: 15,
    is_active: true,
    size: 'A1',
    color: 'white',
    attributes: JSON.stringify({
      material: 'コットン/ポリエステル混紡',
      weight: '400gsm',
      season: '夏用'
    })
  },

  // 帯（Belt）
  {
    name: '白帯 A2サイズ',
    description: '初心者向け白帯。IBJJF規定準拠。耐久性のある厚手素材。',
    price: 2500,
    category: 'belt',
    image_url: 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800',
    stock_quantity: 30,
    is_active: true,
    size: 'A2',
    color: 'white',
    attributes: JSON.stringify({
      width: '4cm',
      material: 'コットン100%'
    })
  },
  {
    name: '青帯 A3サイズ',
    description: '青帯ランク用。耐久性と見た目の美しさを両立。',
    price: 4500,
    category: 'belt',
    image_url: 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800',
    stock_quantity: 18,
    is_active: true,
    size: 'A3',
    color: 'blue',
    attributes: JSON.stringify({
      width: '4cm',
      material: 'コットン100%'
    })
  },
  {
    name: '紫帯 A2サイズ',
    description: '紫帯ランク用。高品質素材使用の上級者向け帯。',
    price: 6000,
    category: 'belt',
    image_url: 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800',
    stock_quantity: 10,
    is_active: true,
    size: 'A2',
    color: 'purple',
    attributes: JSON.stringify({
      width: '4cm',
      material: 'コットン100%'
    })
  },
  {
    name: '茶帯 A2サイズ',
    description: '茶帯ランク用。職人の手による高品質仕上げ。',
    price: 7500,
    category: 'belt',
    image_url: 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800',
    stock_quantity: 5,
    is_active: true,
    size: 'A2',
    color: 'brown',
    attributes: JSON.stringify({
      width: '4cm',
      material: 'コットン100%'
    })
  },
  {
    name: 'ブラック帯 A2サイズ',
    description: 'IBJJF認定黒帯。最高級素材使用、耐久性に優れた高品質仕上げ。',
    price: 8500,
    category: 'belt',
    image_url: 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800',
    stock_quantity: 8,
    is_active: true,
    size: 'A2',
    color: 'black',
    attributes: JSON.stringify({
      width: '4cm',
      material: 'コットン100%',
      certification: 'IBJJF認定'
    })
  },

  // プロテクター（Protector）
  {
    name: 'プロ仕様マウスガード',
    description: '成型可能タイプのマウスガード。安全性を重視した設計。',
    price: 2800,
    category: 'protector',
    image_url: 'https://images.unsplash.com/photo-1609205807107-454f1c1f4a60?w=800',
    stock_quantity: 25,
    is_active: true,
    color: 'clear',
    attributes: JSON.stringify({
      type: '成型タイプ',
      material: 'EVA素材'
    })
  },
  {
    name: 'イヤーガード',
    description: '耳を保護するイヤーガード。長時間の練習でも快適。',
    price: 3500,
    category: 'protector',
    image_url: 'https://images.unsplash.com/photo-1609205807107-454f1c1f4a60?w=800',
    stock_quantity: 15,
    is_active: true,
    color: 'black',
    attributes: JSON.stringify({
      type: 'ソフトタイプ',
      material: 'ネオプレーン'
    })
  },
  {
    name: 'ニーパッド（膝サポーター）',
    description: '膝を保護する高品質サポーター。動きを妨げない設計。',
    price: 4200,
    category: 'protector',
    image_url: 'https://images.unsplash.com/photo-1609205807107-454f1c1f4a60?w=800',
    stock_quantity: 20,
    is_active: true,
    size: 'M',
    color: 'black',
    attributes: JSON.stringify({
      type: '圧縮サポート',
      material: 'ライクラ/ネオプレーン'
    })
  },

  // アパレル（Apparel）
  {
    name: 'JitsuFlow Tシャツ',
    description: '吸湿速乾素材使用のトレーニングTシャツ。快適な着心地。',
    price: 3500,
    category: 'apparel',
    image_url: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800',
    stock_quantity: 15,
    is_active: true,
    size: 'L',
    color: 'black',
    attributes: JSON.stringify({
      material: 'ポリエステル100%',
      feature: '速乾性'
    })
  },
  {
    name: 'ラッシュガード 長袖',
    description: 'UVカット機能付き長袖ラッシュガード。ノーギ練習に最適。',
    price: 5800,
    category: 'apparel',
    image_url: 'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=800',
    stock_quantity: 20,
    is_active: true,
    size: 'M',
    color: 'navy',
    attributes: JSON.stringify({
      material: 'ポリエステル/スパンデックス',
      uvProtection: 'UPF50+'
    })
  },
  {
    name: 'グラップリングショーツ',
    description: '動きやすさを追求したファイトショーツ。耐久性抜群。',
    price: 6500,
    category: 'apparel',
    image_url: 'https://images.unsplash.com/photo-1519861531473-9200262188bf?w=800',
    stock_quantity: 18,
    is_active: true,
    size: '32',
    color: 'black',
    attributes: JSON.stringify({
      material: 'ポリエステル/スパンデックス',
      closure: 'ベルクロ+紐'
    })
  },
  {
    name: 'スパッツ（コンプレッション）',
    description: '筋肉をサポートするコンプレッションスパッツ。',
    price: 4800,
    category: 'apparel',
    image_url: 'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=800',
    stock_quantity: 22,
    is_active: true,
    size: 'M',
    color: 'black',
    attributes: JSON.stringify({
      material: 'ポリエステル/スパンデックス',
      compression: '中圧'
    })
  },

  // 器具（Equipment）
  {
    name: 'グラップリングダミー',
    description: '自宅練習用グラップリングダミー。70kg相当の重量。',
    price: 28000,
    category: 'equipment',
    image_url: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
    stock_quantity: 3,
    is_active: true,
    attributes: JSON.stringify({
      weight: '70kg',
      height: '180cm',
      material: '合成皮革'
    })
  },
  {
    name: '柔術マット 40mm厚',
    description: '高品質EVA素材の柔術専用マット。ジム品質の衝撃吸収。',
    price: 15000,
    category: 'equipment',
    image_url: 'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff?w=800',
    stock_quantity: 7,
    is_active: true,
    attributes: JSON.stringify({
      size: '100cm x 100cm',
      thickness: '40mm',
      material: 'EVA'
    })
  },
  {
    name: 'レジスタンスバンドセット',
    description: '柔術トレーニング用レジスタンスバンド5本セット。',
    price: 8500,
    category: 'equipment',
    image_url: 'https://images.unsplash.com/photo-1598289431512-b97b0917affc?w=800',
    stock_quantity: 12,
    is_active: true,
    attributes: JSON.stringify({
      resistance: '5-50kg',
      quantity: '5本',
      material: 'ラテックス'
    })
  },

  // サプリメント（Supplement）
  {
    name: 'ホエイプロテイン（バニラ）',
    description: '高品質ホエイプロテイン。筋肉回復をサポート。',
    price: 5000,
    category: 'supplement',
    image_url: 'https://images.unsplash.com/photo-1593095948071-474c5cc2989d?w=800',
    stock_quantity: 20,
    is_active: true,
    attributes: JSON.stringify({
      flavor: 'バニラ',
      weight: '1kg',
      servings: '30回分'
    })
  },
  {
    name: 'BCAA（レモン味）',
    description: '疲労回復をサポートするBCAA。トレーニング中の摂取に最適。',
    price: 3800,
    category: 'supplement',
    image_url: 'https://images.unsplash.com/photo-1593095948071-474c5cc2989d?w=800',
    stock_quantity: 25,
    is_active: true,
    attributes: JSON.stringify({
      flavor: 'レモン',
      weight: '500g',
      ratio: '2:1:1'
    })
  },
  {
    name: 'クレアチン',
    description: '瞬発力向上をサポート。純度99.9%のクレアチンモノハイドレート。',
    price: 2800,
    category: 'supplement',
    image_url: 'https://images.unsplash.com/photo-1593095948071-474c5cc2989d?w=800',
    stock_quantity: 18,
    is_active: true,
    attributes: JSON.stringify({
      type: 'モノハイドレート',
      weight: '300g',
      purity: '99.9%'
    })
  },

  // アクセサリー（Accessories）
  {
    name: '道着バッグ',
    description: '道着専用の大容量バッグ。通気性の良いメッシュポケット付き。',
    price: 4500,
    category: 'accessories',
    image_url: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800',
    stock_quantity: 15,
    is_active: true,
    color: 'black',
    attributes: JSON.stringify({
      capacity: '45L',
      material: 'ナイロン',
      features: '防水加工'
    })
  },
  {
    name: 'フィンガーテープ',
    description: '指の保護用テープ。粘着力が強く、剥がれにくい。',
    price: 800,
    category: 'accessories',
    image_url: 'https://images.unsplash.com/photo-1609205807107-454f1c1f4a60?w=800',
    stock_quantity: 50,
    is_active: true,
    attributes: JSON.stringify({
      width: '1.3cm',
      length: '13.7m',
      quantity: '1ロール'
    })
  },
  {
    name: 'タオル（速乾性）',
    description: '速乾性マイクロファイバータオル。コンパクトで持ち運び便利。',
    price: 1500,
    category: 'accessories',
    image_url: 'https://images.unsplash.com/photo-1611088147698-7f54a818df7e?w=800',
    stock_quantity: 30,
    is_active: true,
    color: 'gray',
    attributes: JSON.stringify({
      size: '80cm x 40cm',
      material: 'マイクロファイバー',
      feature: '抗菌加工'
    })
  }
];

/**
 * 商品をデータベースに挿入するための関数
 * @param {Database} db - Cloudflare D1データベース
 */
export async function insertSampleProducts(db) {
  const stmt = db.prepare(`
    INSERT INTO products (
      name, description, price, category, image_url, 
      stock_quantity, is_active, size, color, attributes
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  for (const product of sampleProducts) {
    await stmt.bind(
      product.name,
      product.description,
      product.price,
      product.category,
      product.image_url,
      product.stock_quantity,
      product.is_active ? 1 : 0,
      product.size || null,
      product.color || null,
      product.attributes || null
    ).run();
  }
}
