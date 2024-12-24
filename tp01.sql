-- Requête 1 : Liste des chambres qui ne sont pas au rez-de-chaussée, qui communique avec une autre chambre
-- et qui sont entretenues par les agents (agt_nom) nommés Fechol et Boussel.
SELECT AGT_NOM || ' ' || AGT_PRENOM AS "Agent",
       'Chambre' || ' ' || ch.CHB_NUMERO as "Chambre",
       ch.CHB_ETAGE AS "Etage"
FROM HOTEL.CHAMBRE ch
    JOIN HOTEL.CHAMBRE chC ON (ch.CHB_ID = chC.CHB_COMMUNIQUE)
    JOIN HOTEL.AGENT_ENTRETIEN agt ON (ch.AGT_ID = agt.AGT_ID)
WHERE UPPER(ch.CHB_ETAGE) != 'RDC'
      AND UPPER(AGT_NOM) IN ('FECHOL','BOUSSEL')
ORDER BY 1, 3;

-- Requête 2 : Liste des clients de "REIMS" ayant réservé uen chambre du premier étage entre le 20 et le 25 décembre 2007.
-- Version 1 : Uniquement des jointures 
SELECT DISTINCT tit_lib || ' ' || UPPER(cli_nom) || ' ' || cli_prenom AS "Client"
FROM HOTEL.CLIENT cl 
    JOIN HOTEL.TITRE t ON (cl.TIT_CODE = t.TIT_CODE)
    JOIN HOTEL.ADRESSE ad ON (cl.CLI_ID = ad.CLI_ID)
    JOIN HOTEL.PLANNING pl ON (cl.CLI_ID = pl.CLI_ID)
    JOIN HOTEL.CHAMBRE ch ON (pl.CHB_ID = ch.CHB_ID)
WHERE UPPER(ADR_VILLE) = 'REIMS'
    AND UPPER(CHB_ETAGE) = '1ER'
    AND PLN_JOUR BETWEEN TO_DATE('20/12/2007') AND TO_DATE('25/12/2007');
    
-- Version 2 : Uniquement des sous requêtes lorsque c'est possible 
SELECT DISTINCT tit_lib || ' ' || UPPER(cli_nom) || ' ' || cli_prenom AS "Client"
FROM HOTEL.CLIENT cl 
    JOIN HOTEL.TITRE t ON (cl.TIT_CODE = t.TIT_CODE)
WHERE CLI_ID IN (SELECT CLI_ID
                FROM HOTEL.ADRESSE
                WHERE UPPER(ADR_VILLE)= 'REIMS')
AND CLI_ID IN (SELECT CLI_ID
               FROM HOTEL.PLANNING 
               WHERE PLN_JOUR BETWEEN TO_DATE('20/12/2007') AND TO_DATE('25/12/2007')
               AND CHB_ID IN (SELECT CHB_ID
                              FROM HOTEL.CHAMBRE
                              WHERE UPPER(CHB_ETAGE) = '1ER'));

-- Requête 3 : 
-- a) Donner la liste des agents d'entretien en charge d'au moins une chambre, trié par date d'embauche
SELECT DISTINCT agt_nom || ' ' || agt_prenom AS "Agent", 
       agt_emb AS "Embauche"
FROM HOTEL.AGENT_ENTRETIEN agt
    JOIN HOTEL.CHAMBRE ch ON (agt.AGT_ID = ch.AGT_ID)
ORDER BY 2;

-- b) Idem mais donner le nom uniquement des deux premiers agents + afficher uniquement l'année d'embauche (sous-requête dans le FROM)
SELECT DISTINCT agt_nom || ' ' || agt_prenom AS "Agent", 
       EXTRACT(YEAR FROM agt_emb) AS "Embauche"
FROM (SELECT DISTINCT agt_nom, agt_prenom, agt_emb
      FROM HOTEL.AGENT_ENTRETIEN agt
        JOIN HOTEL.CHAMBRE ch ON (agt.AGT_ID = ch.AGT_ID)
      ORDER BY 3)
WHERE ROWNUM < 3;

-- Requête 4 : 
-- a) Donner le nombre de chambres réservées et le nombre de clients différents pour le mois de nomvembre 2007
SELECT COUNT(ch.chb_id) AS "Nb Réservation",
       COUNT(DISTINCT cl.CLI_ID) AS "Nb Clients"
FROM HOTEL.PLANNING pl
    JOIN HOTEL.CLIENT cl ON (pl.CLI_ID = cl.CLI_ID)
    JOIN HOTEL.CHAMBRE ch ON (pl.CHB_ID = ch.CHB_ID)
WHERE pl.PLN_JOUR BETWEEN TO_DATE('01/11/2007') AND TO_DATE('30/11/2007');

-- b) Donner le nombre de chambres réservées, ainsi que le nombre total (cumul) de personne présentes pour chaque jour du mois de novembre 2007
SELECT TO_CHAR(PLN_JOUR, 'day DD') AS "Jour", 
       COUNT(ch.chb_id) AS "Nb Réservation",
       SUM(NB_PERS) AS "Nb Personne"
FROM HOTEL.PLANNING pl
    JOIN HOTEL.CHAMBRE ch ON (pl.CHB_ID = ch.CHB_ID)
WHERE pl.PLN_JOUR BETWEEN TO_DATE('01/11/2007') AND TO_DATE('30/11/2007')
GROUP BY PLN_JOUR
ORDER BY PLN_JOUR;
    
-- Requête 5 : Liste des jours de 2007 ou l'hotel a été complet
SELECT TO_CHAR(PLN_JOUR, 'fmDay DD Month YYYY') AS "Jours Hôtel Complet"
FROM HOTEL.PLANNING pl 
WHERE EXTRACT(YEAR FROM PLN_JOUR) = 2007
GROUP BY PLN_JOUR
HAVING COUNT(CHB_ID) = (SELECT COUNT(CHB_ID)
                        FROM HOTEL.CHAMBRE);
                        
-- Requête 6 : 
-- a) Donner le numéro, le nom et le prénom des clients pour lesquels plusieurs adresses mail différentes ont été enregistrées
SELECT cl.CLI_ID AS "CLI_ID", 
       TRIM(cl.CLI_NOM) || ' ' || TRIM(cl.CLI_PRENOM) AS "Client", 
       COUNT(EML_ADRESSE) || ' ' || 'adr. mail'  AS "NB ADR."
FROM HOTEL.CLIENT cl 
    JOIN HOTEL.EMAIL e ON (cl.CLI_ID = e.CLI_ID)
GROUP BY cl.CLI_ID, cl.CLI_NOM, cl.CLI_PRENOM
HAVING COUNT(EML_ADRESSE) > 1
ORDER BY 2; 
    
-- b) Meme question mais pour les clients qui ont plusieurs adresses postales et/ou plusieurs mails différentes
SELECT cl.CLI_ID AS "CLI_ID", 
       TRIM(cl.CLI_NOM) || ' ' || TRIM(cl.CLI_PRENOM) AS "Client", 
       COUNT(EML_ADRESSE) || ' ' || 'adr. mail'  AS "Plusieurs ADR."
FROM HOTEL.CLIENT cl 
    JOIN HOTEL.EMAIL e ON (cl.CLI_ID = e.CLI_ID)
GROUP BY cl.CLI_ID, cl.CLI_NOM, cl.CLI_PRENOM
HAVING COUNT(EML_ADRESSE) > 1
UNION 
SELECT cl.CLI_ID AS "CLI_ID", 
       TRIM(cl.CLI_NOM) || ' ' || TRIM(cl.CLI_PRENOM) AS "Client", 
       COUNT(ADR_ID) || ' ' || 'adr. postales'  AS "Plusieurs ADR."
FROM HOTEL.CLIENT cl 
    JOIN HOTEL.ADRESSE a ON (cl.CLI_ID = a.CLI_ID)
GROUP BY cl.CLI_ID, cl.CLI_NOM, cl.CLI_PRENOM
HAVING COUNT(ADR_ID) > 1
ORDER BY 2;

-- Requête 7 : Liste des agents d'entretien qui ont entre 50 et 60 ans avec les chambres qu'ils ont en charge. Les agents non affectés doivent apparaitre
SELECT NVL2(AGT_SX, 'M.', 'Mme') || ' ' || AGT_NOM || ' ' || AGT_PRENOM AS "Agent", 
       ROUND((SYSDATE - AGT_DNAIS)/ 365.25) AS "Age", 
       NVL2(CHB_ID, 'N°' || '' || CHB_ID, 'Aucune Chambre') AS "Chambre", 
       NVL(CHB_ETAGE, '--') AS "Etage"
FROM HOTEL.AGENT_ENTRETIEN agt
    LEFT JOIN HOTEL.CHAMBRE ch ON (agt.AGT_ID = ch.AGT_ID)
WHERE (SYSDATE - AGT_DNAIS)/ 365.25 BETWEEN 50 AND 60;

-- Requête 8 : Liste des clients mémorisés dans la base mais qui n'ont jamais effectué de réservation à l'hotel
-- a) Avec une jointure externe 
SELECT DISTINCT CLI_NOM ||' '||CLI_PRENOM AS "Nom - Prénom", 
        ADR_LIGNE1 AS "Adresse",
        ADR_CP AS "Code Postal", 
        ADR_VILLE AS "Ville"
FROM HOTEL.CLIENT cl
    JOIN HOTEL.ADRESSE ad ON (cl.CLI_ID = ad.CLI_ID)
    LEFT JOIN HOTEL.PLANNING pl ON (cl.CLI_ID = pl.CLI_ID)
WHERE pl.CLI_ID IS NULL
AND ADR_ID = 1;

-- b) Avec une sous requête (opérateur =, IN, ou NOT IN)
SELECT DISTINCT CLI_NOM ||' '||CLI_PRENOM AS "Nom - Prénom", 
        ADR_LIGNE1 AS "Adresse",
        ADR_CP AS "Code Postal", 
        ADR_VILLE AS "Ville"
FROM HOTEL.CLIENT cl 
    JOIN HOTEL.ADRESSE ad ON (cl.CLI_ID = ad.CLI_ID)
WHERE cl.CLI_ID NOT IN (SELECT CLI_ID FROM HOTEL.PLANNING)
AND ADR_ID = 1;

-- c) Avec une sous requête (opérateur EXISTS ou NOT EXISTS)
SELECT DISTINCT CLI_NOM ||' '||CLI_PRENOM AS "Nom - Prénom", 
        ADR_LIGNE1 AS "Adresse",
        ADR_CP AS "Code Postal", 
        ADR_VILLE AS "Ville"
FROM HOTEL.CLIENT cl 
    JOIN HOTEL.ADRESSE ad ON (cl.CLI_ID = ad.CLI_ID)
WHERE NOT EXISTS (SELECT NULL 
                 FROM HOTEL.PLANNING pl 
                 WHERE cl.CLI_ID = pl.CLI_ID)
AND ADR_ID = 1;


-- d) Avec un opérateur de la théorie des ensembles
SELECT DISTINCT CLI_NOM ||' '||CLI_PRENOM AS "Nom - Prénom", 
        ADR_LIGNE1 AS "Adresse",
        ADR_CP AS "Code Postal", 
        ADR_VILLE AS "Ville"
FROM HOTEL.CLIENT cl 
    JOIN HOTEL.ADRESSE ad ON (cl.CLI_ID = ad.CLI_ID)
WHERE ADR_ID = 1
MINUS
SELECT DISTINCT CLI_NOM ||' '||CLI_PRENOM AS "Nom - Prénom", 
        ADR_LIGNE1 AS "Adresse",
        ADR_CP AS "Code Postal", 
        ADR_VILLE AS "Ville"
FROM HOTEL.CLIENT cl 
    JOIN HOTEL.ADRESSE ad ON (cl.CLI_ID = ad.CLI_ID)
    JOIN HOTEL.PLANNING pl ON (cl.CLI_ID = pl.CLI_ID)
WHERE ADR_ID = 1;

-- Requête 9 : Donner les clients ayant cumulé le plus grand nombre de jours passées à l'hotel en 2007 
SELECT TRIM(TIT_CODE) || ' ' || TRIM(CLI_NOM) || ' ' || TRIM(CLI_PRENOM) AS "Meilleur client 2007", 
        EML_ADRESSE AS "Adresse",
        COUNT(DISTINCT PLN_JOUR) AS "Nb Jours"
FROM HOTEL.CLIENT cl
    JOIN HOTEL.EMAIL e ON (cl.CLI_ID = e.CLI_ID)
    JOIN HOTEL.PLANNING pl ON (cl.CLI_ID = pl.CLI_ID)
WHERE EXTRACT(YEAR FROM PLN_JOUR) = 2007
GROUP BY TIT_CODE, CLI_NOM, CLI_PRENOM, EML_ADRESSE
HAVING COUNT(PLN_JOUR) = (SELECT MAX(COUNT(PLN_JOUR))
                                FROM HOTEL.PLANNING
                                WHERE EXTRACT(YEAR FROM PLN_JOUR) = 2007
                                GROUP BY CLI_ID);
                                
-- Requête 10 : 
-- a) Liste de tous les clients de Paris avec leurs adresses mail. Les afficher même s'ils n'ont pas d'adresse email
SELECT TRIM(CLI_NOM) AS "Nom",
       TRIM(CLI_PRENOM) AS "Prénom", 
       NVL(EML_ADRESSE, '--') AS "Adr. Email"
FROM HOTEL.CLIENT cl
    LEFT JOIN HOTEL.EMAIL e ON (cl.CLI_ID = e.CLI_ID)
    JOIN HOTEL.ADRESSE ad ON (cl.CLI_ID = ad.CLI_ID)
WHERE UPPER(ADR_VILLE) LIKE '%PARIS%';

-- b) Liste de tous les clients de Paris avec, s'ils en ont, leurs numéros de FAX ainsi que leurs adresses mail. 
SELECT CLI_NOM AS Nom,
    CLI_PRENOM AS Prénom,
    TEL_NUMERO
FROM HOTEL.CLIENT cl, HOTEL.ADRESSE ad, HOTEL.EMAIL em,
    (SELECT * FROM HOTEL.TELEPHONE WHERE UPPER(TYP_CODE) LIKE 'FAX%') tel
WHERE cl.CLI_ID = ad.CLI_ID (+) 
AND cl.CLI_ID = em.CLI_ID (+)
AND cl.CLI_ID = tel.CLI_ID (+)
AND UPPER(ADR_VILLE) LIKE '%PARIS%';

-- Requête 11 : Liste des chambres avec numéro des clients qui les ont réservées le 26 décembre 2007. Les chambres n'ayant pas été réservées ce jour-la devront malgré tout apparaitre dans la liste. 
SELECT 'Chambre N°' || '' || ch.CHB_NUMERO AS "Chambre", 
       cl.CLI_ID AS "N°Client"
FROM HOTEL.CHAMBRE ch
    LEFT JOIN HOTEL.PLANNING pl ON (pl.CHB_ID = ch.CHB_ID AND pl.PLN_JOUR = TO_DATE('26/12/2007', 'DD/MM/YYYY'))
    LEFT JOIN HOTEL.CLIENT cl ON (pl.CLI_ID = cl.CLI_ID);
    
SELECT 'Chambre N°' ||''|| CHB_NUMERO AS "Chambre", 
        cl.CLI_ID AS "Numero Cl."
FROM HOTEL.CLIENT cl, (SELECT * FROM HOTEL.PLANNING WHERE PLN_JOUR = TO_DATE('26/12/2007', 'DD/MM/YYYY')) pl, HOTEL.CHAMBRE ch
WHERE cl.CLI_ID(+) = pl.CLI_ID 
    AND pl.CHB_ID(+) = ch.CHB_ID;
    
-- b) Modifier l'une des requêtes pour qu'elle affiche les noms et prénoms des clients à la place des numéros
SELECT 'Chambre N°' ||''|| CHB_NUMERO AS "Chambre", 
        NVL2(TRIM(cl.CLI_ID), TRIM(CLI_NOM) || ' ' || TRIM(CLI_PRENOM), 'NON RESERVE') AS "Numero Cl."
FROM HOTEL.Chambre ch
    LEFT JOIN HOTEL.Planning pl ON (ch.CHB_ID = pl.CHB_ID AND PLN_JOUR = TO_DATE('26/12/2007', 'DD/MM/YYYY'))
    LEFT JOIN HOTEL.Client cl ON (pl.CLI_ID = cl.CLI_ID)
ORDER BY CHB_NUMERO;

    
-- Requête 12 : Liste des agents d'entretien de sexe féminin avec le nombre de chambres de plus de 2 couchages qu'elles ont en charge. 
SELECT AGT_NOM AS "Agent Entretien",
    CASE COUNT(CHB_ID)
        WHEN 0 THEN 'Pas de chambre de plus de 2 couchage'
        ELSE TO_CHAR(COUNT(CHB_ID)) || ' Chambre de plus de 2 couchages'
    END AS "Nb Chambres"
FROM HOTEL.CHAMBRE c 
    RIGHT JOIN HOTEL.AGENT_ENTRETIEN ae on (c.AGT_ID = ae.AGT_ID AND CHB_COUCHAGE > 2)
WHERE AGT_SX = 2
GROUP BY AGT_NOM;

-- Requête 13 : Liste des clients qui ne sont pas de la marne et qui n'ont pas séjourné à l'hotel (uniquement des jointures)
SELECT TRIM(CLI_NOM) AS Client,
    ADR_VILLE AS Ville,
    CASE 
        WHEN UPPER(typ_code) = 'TEL' THEN TEL_NUMERO
        ELSE 'Numéro inconnu'
    END AS "Telephone" 
FROM HOTEL.CLIENT cl 
    LEFT JOIN HOTEL.TELEPHONE tel ON (cl.CLI_ID = tel.CLI_ID AND UPPER(typ_code) = 'TEL')
    JOIN HOTEL.ADRESSE ad ON (cl.CLI_ID = ad.CLI_ID AND ADR_ID = 1)
    LEFT JOIN HOTEL.PLANNING pl ON (cl.CLI_ID = pl.CLI_ID)
WHERE ADR_CP NOT LIKE '51%'
AND PLN_JOUR IS NULL
ORDER BY CLI_NOM;

















    
    
    
    