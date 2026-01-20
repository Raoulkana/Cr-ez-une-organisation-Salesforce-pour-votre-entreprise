// ===============================
// 1. PRICEBOOK "FRANCE"
// ===============================
Pricebook2 pb;
List<Pricebook2> pbs = [
    SELECT Id FROM Pricebook2
    WHERE Name = 'Liste des prix - FRANCE'
    LIMIT 1
];

if (pbs.isEmpty()) {
    pb = new Pricebook2(Name='Liste des prix - FRANCE', IsActive=true);
    insert pb;
} else {
    pb = pbs[0];
}

// ===============================
// 2. PRODUITS (clé = SKU)
// ===============================
Map<String, Product2> existingProducts = new Map<String, Product2>();
for (Product2 p : [
    SELECT Id, StockKeepingUnit
    FROM Product2
    WHERE StockKeepingUnit IN (
        'TES-MS-2022',
        'FORD-MM-2022',
        'AUDI-ET-2022',
        'TOY-CH-2022',
        'HON-CIV-2022'
    )
]) {
    existingProducts.put(p.StockKeepingUnit, p);
}

List<Product2> productsToInsert = new List<Product2>();

if (!existingProducts.containsKey('TES-MS-2022')) {
    productsToInsert.add(new Product2(
        Name='Tesla Model S',
        ProductCode='TES-MS',
        Family='Voitures électriques',
        Description='Voiture électrique haut de gamme',
        StockKeepingUnit='TES-MS-2022',
        QuantityInStock__c=50
    ));
}

if (!existingProducts.containsKey('FORD-MM-2022')) {
    productsToInsert.add(new Product2(
        Name='Ford Mustang Mach-E',
        ProductCode='FORD-MM',
        Family='Voitures électriques',
        Description='SUV électrique',
        StockKeepingUnit='FORD-MM-2022',
        QuantityInStock__c=75
    ));
}

if (!existingProducts.containsKey('AUDI-ET-2022')) {
    productsToInsert.add(new Product2(
        Name='Audi e-Tron',
        ProductCode='AUDI-ET',
        Family='Voitures électriques',
        Description='SUV électrique',
        StockKeepingUnit='AUDI-ET-2022',
        QuantityInStock__c=100
    ));
}

if (!existingProducts.containsKey('TOY-CH-2022')) {
    productsToInsert.add(new Product2(
        Name='Toyota Corolla Hybride',
        ProductCode='TOY-CH',
        Family='Voitures hybrides',
        Description='Voiture hybride',
        StockKeepingUnit='TOY-CH-2022',
        QuantityInStock__c=150
    ));
}

if (!existingProducts.containsKey('HON-CIV-2022')) {
    productsToInsert.add(new Product2(
        Name='Honda Civic',
        ProductCode='HON-CIV',
        Family='Voitures à essence',
        Description='Voiture essence',
        StockKeepingUnit='HON-CIV-2022',
        QuantityInStock__c=200
    ));
}

if (!productsToInsert.isEmpty()) {
    insert productsToInsert;
}

// Recharger tous les produits
List<Product2> products = [
    SELECT Id, StockKeepingUnit
    FROM Product2
    WHERE StockKeepingUnit IN (
        'TES-MS-2022',
        'FORD-MM-2022',
        'AUDI-ET-2022',
        'TOY-CH-2022',
        'HON-CIV-2022'
    )
];

// ===============================
// 3. PRICEBOOK STANDARD
// ===============================
Pricebook2 standardPb = [
    SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1
];

// ===============================
// 4. PRICEBOOK ENTRIES
// ===============================
Map<String, Id> productBySku = new Map<String, Id>();
for (Product2 p : products) {
    productBySku.put(p.StockKeepingUnit, p.Id);
}

List<PricebookEntry> entriesToInsert = new List<PricebookEntry>();

for (Product2 p : products) {
    if ([SELECT COUNT() FROM PricebookEntry
         WHERE Product2Id = :p.Id AND Pricebook2Id = :standardPb.Id] == 0) {

        entriesToInsert.add(new PricebookEntry(
            Pricebook2Id = standardPb.Id,
            Product2Id   = p.Id,
            UnitPrice    = 25000,
            IsActive     = true
        ));
    }
}

// FRANCE pricebook
Map<String, Decimal> prices = new Map<String, Decimal>{
    'TES-MS-2022' => 99990,
    'FORD-MM-2022' => 69900,
    'AUDI-ET-2022' => 82400,
    'TOY-CH-2022' => 28990,
    'HON-CIV-2022' => 26990
};

for (String sku : prices.keySet()) {
    if ([SELECT COUNT() FROM PricebookEntry
         WHERE Product2Id = :productBySku.get(sku)
         AND Pricebook2Id = :pb.Id] == 0) {

        entriesToInsert.add(new PricebookEntry(
            Pricebook2Id = pb.Id,
            Product2Id   = productBySku.get(sku),
            UnitPrice    = prices.get(sku),
            IsActive     = true
        ));
    }
}

if (!entriesToInsert.isEmpty()) {
    insert entriesToInsert;
}

System.debug('✔ Script exécuté avec succès (idempotent)');
