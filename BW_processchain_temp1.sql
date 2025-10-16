  -- get steps from process chain which has been executed at least ones
  -- *we can filter the list by checking all PCs ran in 2025 year alone.
DECLARE
  v_chain string DEFAULT 'ZPC_SD_C02';
DECLARE
  v_logs string;
DECLARE
  v_steps ARRAY<string>;
SET
  v_logs = (
  SELECT
    log_id
  FROM
    `sap-iac-test.bq_toolkit_bw7.rspclogchain`
  WHERE
    chain_id = v_chain
  ORDER BY
    datum,
    zeit DESC
  LIMIT
    1);
  -- select v_logs;
SET
  v_steps = (
  SELECT
    ARRAY_AGG(variante
    ORDER BY
      starttimestamp ASC)
  FROM
    `sap-iac-test.bq_toolkit_bw7.rspcprocesslog`
  WHERE
    log_id = v_logs);
  -- select * from unnest(v_steps) as steps;
  -- sequence of steps is correct till this point. Need to keep the sequence intact further
  -- get process type for each
SELECT
  a.variante,
  a.type,
  coalesce (ip.text,dtp.txtlg) as text
FROM
  `sap-iac-test.bq_toolkit_bw7.rspcchain` as a
left OUTER JOIN
  `sap-iac-test.bq_toolkit_bw7.rsldpiot` as ip
ON
  a.variante = ip.logdpid
  AND a.objvers = ip.objvers
    AND ip.langu = 'E'
  left outer join `sap-iac-test.bq_toolkit_bw7.rsbkdtpt` as dtp
  on a.variante = dtp.dtp 
  and a.objvers = dtp.objvers
  and dtp.langu = 'E'
WHERE
  a.chain_id = v_chain
  AND a.objvers = 'A'
  AND a.variante IN (
  SELECT
    *
  FROM
    UNNEST(v_steps) AS steps)
  ;
  -- then update text information for each step