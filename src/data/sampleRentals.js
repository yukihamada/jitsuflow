/**
 * サンプルレンタル商品データ
 * JitsuFlow道場レンタル用の初期データ
 */

export const sampleRentals = [
  // 道着レンタル
  {
    item_type: 'gi',
    item_name: '道着（白帯用）',
    size: 'A0',
    color: 'white',
    condition: 'good',
    dojo_id: 1,
    total_quantity: 3,
    available_quantity: 3,
    rental_price: 1000,
    deposit_amount: 5000,
    status: 'available',
    notes: '初心者向けの清潔な道着。毎回洗濯済み。'
  },
  {
    item_type: 'gi',
    item_name: '道着（白帯用）',
    size: 'A1',
    color: 'white',
    condition: 'good',
    dojo_id: 1,
    total_quantity: 5,
    available_quantity: 5,
    rental_price: 1000,
    deposit_amount: 5000,
    status: 'available',
    notes: '標準サイズの道着。快適な着心地。'
  },
  {
    item_type: 'gi',
    item_name: '道着（白帯用）',
    size: 'A2',
    color: 'white',
    condition: 'good',
    dojo_id: 1,
    total_quantity: 5,
    available_quantity: 4,
    rental_price: 1000,
    deposit_amount: 5000,
    status: 'available',
    notes: '人気のサイズ。早めの予約推奨。'
  },
  {
    item_type: 'gi',
    item_name: '道着（白帯用）',
    size: 'A3',
    color: 'white',
    condition: 'good',
    dojo_id: 1,
    total_quantity: 4,
    available_quantity: 4,
    rental_price: 1000,
    deposit_amount: 5000,
    status: 'available',
    notes: '大きめサイズの道着。'
  },
  {
    item_type: 'gi',
    item_name: '道着（白帯用）',
    size: 'A4',
    color: 'white',
    condition: 'good',
    dojo_id: 1,
    total_quantity: 2,
    available_quantity: 2,
    rental_price: 1000,
    deposit_amount: 5000,
    status: 'available',
    notes: '特大サイズ。在庫限定。'
  },
  {
    item_type: 'gi',
    item_name: '道着（色帯用）',
    size: 'A2',
    color: 'blue',
    condition: 'excellent',
    dojo_id: 1,
    total_quantity: 2,
    available_quantity: 2,
    rental_price: 1500,
    deposit_amount: 8000,
    status: 'available',
    notes: 'IBJJF認定の試合用道着。'
  },

  // 帯レンタル
  {
    item_type: 'belt',
    item_name: '白帯',
    size: 'A1',
    color: 'white',
    condition: 'good',
    dojo_id: 1,
    total_quantity: 10,
    available_quantity: 8,
    rental_price: 300,
    deposit_amount: 1000,
    status: 'available',
    notes: '初心者用の白帯。'
  },
  {
    item_type: 'belt',
    item_name: '白帯',
    size: 'A2',
    color: 'white',
    condition: 'good',
    dojo_id: 1,
    total_quantity: 10,
    available_quantity: 9,
    rental_price: 300,
    deposit_amount: 1000,
    status: 'available',
    notes: '標準サイズの白帯。'
  },
  {
    item_type: 'belt',
    item_name: '青帯',
    size: 'A2',
    color: 'blue',
    condition: 'good',
    dojo_id: 1,
    total_quantity: 5,
    available_quantity: 5,
    rental_price: 500,
    deposit_amount: 2000,
    status: 'available',
    notes: '青帯ランク用。'
  },

  // ラッシュガードレンタル
  {
    item_type: 'rashguard',
    item_name: 'ラッシュガード（長袖）',
    size: 'S',
    color: 'black',
    condition: 'good',
    dojo_id: 1,
    total_quantity: 3,
    available_quantity: 3,
    rental_price: 800,
    deposit_amount: 3000,
    status: 'available',
    notes: 'ノーギ練習用。UVカット機能付き。'
  },
  {
    item_type: 'rashguard',
    item_name: 'ラッシュガード（長袖）',
    size: 'M',
    color: 'black',
    condition: 'good',
    dojo_id: 1,
    total_quantity: 5,
    available_quantity: 4,
    rental_price: 800,
    deposit_amount: 3000,
    status: 'available',
    notes: '人気の標準サイズ。'
  },
  {
    item_type: 'rashguard',
    item_name: 'ラッシュガード（長袖）',
    size: 'L',
    color: 'black',
    condition: 'good',
    dojo_id: 1,
    total_quantity: 5,
    available_quantity: 5,
    rental_price: 800,
    deposit_amount: 3000,
    status: 'available',
    notes: '大きめサイズ。快適な着心地。'
  },
  {
    item_type: 'rashguard',
    item_name: 'ラッシュガード（長袖）',
    size: 'XL',
    color: 'black',
    condition: 'good',
    dojo_id: 1,
    total_quantity: 3,
    available_quantity: 3,
    rental_price: 800,
    deposit_amount: 3000,
    status: 'available',
    notes: '特大サイズ。'
  },

  // ファイトショーツレンタル
  {
    item_type: 'shorts',
    item_name: 'ファイトショーツ',
    size: '30',
    color: 'black',
    condition: 'good',
    dojo_id: 1,
    total_quantity: 3,
    available_quantity: 3,
    rental_price: 700,
    deposit_amount: 2500,
    status: 'available',
    notes: 'ノーギ用ショーツ。動きやすい設計。'
  },
  {
    item_type: 'shorts',
    item_name: 'ファイトショーツ',
    size: '32',
    color: 'black',
    condition: 'good',
    dojo_id: 1,
    total_quantity: 5,
    available_quantity: 4,
    rental_price: 700,
    deposit_amount: 2500,
    status: 'available',
    notes: '標準サイズ。人気商品。'
  },
  {
    item_type: 'shorts',
    item_name: 'ファイトショーツ',
    size: '34',
    color: 'black',
    condition: 'good',
    dojo_id: 1,
    total_quantity: 4,
    available_quantity: 4,
    rental_price: 700,
    deposit_amount: 2500,
    status: 'available',
    notes: '大きめサイズ。'
  },

  // プロテクターレンタル
  {
    item_type: 'protector',
    item_name: 'マウスガード',
    size: 'one_size',
    color: 'clear',
    condition: 'new',
    dojo_id: 1,
    total_quantity: 20,
    available_quantity: 18,
    rental_price: 500,
    deposit_amount: 1500,
    status: 'available',
    notes: '新品の成型タイプ。衛生的。'
  },
  {
    item_type: 'protector',
    item_name: 'イヤーガード',
    size: 'one_size',
    color: 'black',
    condition: 'good',
    dojo_id: 1,
    total_quantity: 10,
    available_quantity: 9,
    rental_price: 600,
    deposit_amount: 2000,
    status: 'available',
    notes: '耳の保護用。調整可能。'
  },

  // 道場2のレンタル品
  {
    item_type: 'gi',
    item_name: '道着（白帯用）',
    size: 'A1',
    color: 'white',
    condition: 'good',
    dojo_id: 2,
    total_quantity: 4,
    available_quantity: 4,
    rental_price: 1000,
    deposit_amount: 5000,
    status: 'available',
    notes: 'Over Limit Sapporo専用道着。'
  },
  {
    item_type: 'gi',
    item_name: '道着（白帯用）',
    size: 'A2',
    color: 'white',
    condition: 'good',
    dojo_id: 2,
    total_quantity: 6,
    available_quantity: 5,
    rental_price: 1000,
    deposit_amount: 5000,
    status: 'available',
    notes: '人気サイズ。清潔管理徹底。'
  },
  {
    item_type: 'gi',
    item_name: '道着（白帯用）',
    size: 'A3',
    color: 'white',
    condition: 'good',
    dojo_id: 2,
    total_quantity: 3,
    available_quantity: 3,
    rental_price: 1000,
    deposit_amount: 5000,
    status: 'available',
    notes: '大きめサイズ完備。'
  },

  // 道場3のレンタル品
  {
    item_type: 'gi',
    item_name: '道着（白帯用）',
    size: 'A0',
    color: 'white',
    condition: 'excellent',
    dojo_id: 3,
    total_quantity: 2,
    available_quantity: 2,
    rental_price: 1200,
    deposit_amount: 6000,
    status: 'available',
    notes: 'スイープ道場プレミアム道着。'
  },
  {
    item_type: 'gi',
    item_name: '道着（白帯用）',
    size: 'A1',
    color: 'white',
    condition: 'excellent',
    dojo_id: 3,
    total_quantity: 4,
    available_quantity: 4,
    rental_price: 1200,
    deposit_amount: 6000,
    status: 'available',
    notes: '高品質道着。快適性重視。'
  },
  {
    item_type: 'gi',
    item_name: '道着（白帯用）',
    size: 'A2',
    color: 'white',
    condition: 'excellent',
    dojo_id: 3,
    total_quantity: 4,
    available_quantity: 3,
    rental_price: 1200,
    deposit_amount: 6000,
    status: 'available',
    notes: 'プレミアム仕様。試合でも使用可。'
  },
  {
    item_type: 'rashguard',
    item_name: 'ラッシュガード（長袖）',
    size: 'M',
    color: 'navy',
    condition: 'excellent',
    dojo_id: 3,
    total_quantity: 4,
    available_quantity: 4,
    rental_price: 1000,
    deposit_amount: 4000,
    status: 'available',
    notes: 'スイープオリジナルデザイン。'
  },
  {
    item_type: 'rashguard',
    item_name: 'ラッシュガード（長袖）',
    size: 'L',
    color: 'navy',
    condition: 'excellent',
    dojo_id: 3,
    total_quantity: 4,
    available_quantity: 3,
    rental_price: 1000,
    deposit_amount: 4000,
    status: 'available',
    notes: '高品質素材使用。'
  }
];

/**
 * レンタル品をデータベースに挿入するための関数
 * @param {Database} db - Cloudflare D1データベース
 */
export async function insertSampleRentals(db) {
  const stmt = db.prepare(`
    INSERT INTO rentals (
      item_type, item_name, size, color, condition, dojo_id,
      total_quantity, available_quantity, rental_price, 
      deposit_amount, status, notes
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  for (const rental of sampleRentals) {
    await stmt.bind(
      rental.item_type,
      rental.item_name,
      rental.size || null,
      rental.color || null,
      rental.condition,
      rental.dojo_id,
      rental.total_quantity,
      rental.available_quantity,
      rental.rental_price,
      rental.deposit_amount,
      rental.status,
      rental.notes || null
    ).run();
  }
}
