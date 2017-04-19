DROP VIEW IF EXISTS ProductMetaView,ProductCategoryView,OrderView,OrderMetaViewPV,OrderMetaView,OrderTotalsView,OrderDetailTotalsView,OrderDetailTotals;

CREATE VIEW ProductMetaView AS SELECT p.ID pv_id, (CASE
        WHEN p.post_parent IN (0,'') THEN
            p.ID
        ELSE
            p.post_parent
        END) product_id, pm.meta_value sku, p.post_type post_type 
FROM `wp_xeroshoes_postmeta` pm 
INNER JOIN `wp_xeroshoes_posts` p ON p.ID = pm.post_id
WHERE pm.meta_key = '_sku'
AND p.post_type IN ('product_variation','product') 
AND p.post_status = 'publish';
#SELECT * FROM ProductMetaView

CREATE VIEW ProductCategoryView AS
SELECT wp_xeroshoes_term_relationships.object_id product_id, GROUP_CONCAT(wp_xeroshoes_terms.name SEPARATOR ', ') product_cat
FROM wp_xeroshoes_term_relationships,wp_xeroshoes_term_taxonomy,wp_xeroshoes_terms 
WHERE wp_xeroshoes_term_relationships.term_taxonomy_id = wp_xeroshoes_term_taxonomy.term_taxonomy_id AND
wp_xeroshoes_term_taxonomy.term_id = wp_xeroshoes_terms.term_id AND
wp_xeroshoes_term_taxonomy.taxonomy = 'product_cat'
GROUP BY wp_xeroshoes_term_relationships.object_id;
#SELECT * FROM ProductCategoryView 

CREATE VIEW OrderMetaViewPV AS
SELECT DISTINCT woim.order_item_id order_item_id,(CASE
        WHEN woim2.meta_value IN (0,'') THEN
            woim.meta_value
        ELSE
            woim2.meta_value
        END) pv_id, woim.meta_value product_id,woim5.meta_value _qty, woim3.meta_value _line_subtotal,woim4.meta_value _line_total,woi.order_item_name,woi.order_item_type,woi.order_id order_id
FROM (((((`wp_xeroshoes_woocommerce_order_itemmeta` woim
JOIN `wp_xeroshoes_woocommerce_order_itemmeta` woim2 ON woim.order_item_id = woim2.order_item_id)
JOIN `wp_xeroshoes_woocommerce_order_itemmeta` woim3 ON woim.order_item_id = woim3.order_item_id)
JOIN `wp_xeroshoes_woocommerce_order_itemmeta` woim4 ON woim.order_item_id = woim4.order_item_id)
JOIN `wp_xeroshoes_woocommerce_order_itemmeta` woim5 ON woim.order_item_id = woim5.order_item_id)
JOIN `wp_xeroshoes_woocommerce_order_items` woi ON  woim.order_item_id =  woi.order_item_id )
WHERE woim.meta_key = '_product_id'
AND woim2.meta_key = '_variation_id'
AND woim3.meta_key = '_line_subtotal'
AND woim4.meta_key = '_line_total'
AND woim5.meta_key = '_qty';
#SELECT * FROM OrderMetaViewPV 

CREATE VIEW OrderView AS
SELECT ID order_id,post_date order_date FROM wp_xeroshoes_posts p
WHERE p.post_type = 'shop_order'
AND p.post_status = 'wc-completed' ;
#SELECT * FROM OrderView

CREATE VIEW OrderMetaView AS
SELECT omvpv.order_id,order_item_name,pv_id,SUM(_qty) qty,ROUND(SUM(_line_subtotal), 2) line_subtotal, ROUND(SUM(_line_total), 2) line_total
FROM OrderMetaViewPV omvpv
JOIN OrderView ov ON omvpv.order_id = ov.order_id
GROUP BY pv_id;
#WHERE ov.order_date BETWEEN ;
#SELECT * FROM OrderMetaView

CREATE VIEW OrderTotalsView AS
SELECT pcv.product_cat,omv.order_id, omv.pv_id,pmv.sku,omv.qty,pmv.post_type, omv.line_subtotal, omv.line_total
FROM ((OrderMetaView omv 
JOIN ProductMetaView pmv ON omv.pv_id = pmv.pv_id)
JOIN ProductCategoryView pcv ON pmv.product_id = pcv.product_id);
#SELECT * FROM OrderTotalsView 

CREATE VIEW OrderDetailTotals AS
SELECT otv.product_cat 'Assigned Categories',pv_id 'Product ID',sku 'SKU',otv.qty 'Quantity',post_type 'Product Type',line_subtotal 'Gross Sales',line_total 'Net Sales'
FROM OrderTotalsView otv
JOIN OrderView ov ON otv.order_id = ov.order_id;

#SELECT * FROM OrderDetailTotalsView LIMIT 5

