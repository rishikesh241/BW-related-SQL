SELECT object_value, COUNT(*) AS changes FROM `sap-iac-test.sapam_dataset.change_document_item` 
WHERE old_value <> new_value
GROUP BY ALL ORDER BY changes DESC

SELECT COUNT(DISTINCT(change_number)) FROM `sap-iac-test.sapam_dataset.change_document_item` WHERE object_value = '10030010000422515'

SELECT * FROM `sap-iac-test.sapam_dataset.change_document_item` WHERE object_value = '10030010000422515'

SELECT COUNT(DISTINCT table_key) FROM `sap-iac-test.sapam_dataset.change_document_item`
WHERE object_value = '10030010000422515'
AND old_value <> new_value