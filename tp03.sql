SET SERVEROUTPUT ON;
-- Exercice 1 : 
-- a) Lister les agents d'entretien de l'hôtel encore en poste, triés par âge décroissant 
SELECT AGT_NOM || ' ' || AGT_PRENOM || ' - ' || ROUND((SYSDATE - AGT_DNAIS) / 365.25) || ' ans' AS "Agent"
FROM AGENT_ENTRETIEN
WHERE AGT_DPT IS NULL
ORDER BY ROUND((SYSDATE - AGT_DNAIS) / 365.25) DESC;

-- b) Ecrire en PL/SQL un déclencheur permettant de rejeter la mise à jour de la table AGENT_ENTRETIEN le lundi (ou autre jour pour les tests)
CREATE OR REPLACE TRIGGER TR_jourOk
BEFORE INSERT OR UPDATE OR DELETE ON AGENT_ENTRETIEN
DECLARE 
    v_jour VARCHAR(20);
BEGIN 
    v_jour := TO_CHAR(SYSDATE, 'fmday', 'NLS_DATE_LANGUAGE = French');
    IF v_jour = 'vendredi' 
        THEN RAISE_APPLICATION_ERROR(-20000, 'Ce n''est pas autorise aujourd''hui');
    END IF;
END;
/ 

-- c) Tester le déclencheur en tentant une insertion dans la table AGENT_ENTRETIEN 
INSERT INTO AGENT_ENTRETIEN (AGT_ID, AGT_NOM, AGT_PRENOM, AGT_DNAIS, AGT_EMB, AGT_SALAIRE)
    VALUES ('A07', 'DELON', 'ALAIN', '01-01-1952', '03-03-2016', 1500);
    
-- d) Désactiver le déclencheur jour_ok
ALTER TRIGGER TR_jourOk DISABLE;
    
-- Exercice 2 
-- 1) Afficher le détail des lignes des factures payées par chèque et liées à une adresse de l'Aisne
SELECT lf.FAC_ID, f.CLI_ID, a.ADR_ID, MNT, PMT_CODE
FROM LIGNE_FACTURE lf, 
    (SELECT * FROM FACTURE WHERE UPPER(PMT_CODE) = 'CHQ') f,
    (SELECT * FROM ADRESSE WHERE ADR_CP LIKE '02%') a
WHERE f.FAC_ID = lf.FAC_ID 
AND f.CLI_ID = a.CLI_ID
AND f.ADR_ID = a.ADR_ID;

-- 2) Tenter de supprimer la facture N°1476
DELETE FROM FACTURE
    WHERE FAC_ID = '1476';
-- a) Pourquoi cette commande déclenche-t-elle une erreur ? 
-- Cette commande déclenche une erreur car elle est liée à une ligne de facture. 

-- b) Quelles solutions pourraient permettre de supprimer automatiquement les lignes des factures lors de la suppression d'une facture ?
-- On pourrait mofifier la contrainte d'intégrité pour ajout l'option ON DELETE CASCADE
-- On pourrait crée un Trigger

-- 3) 
-- a) Créer les tables OLD_FACT et OLD_LG avec les meme champs que les tables FACTURE et LIGNE_FACTURE
CREATE TABLE OLD_FACT (
   FAC_ID               INTEGER                          not null,
   PMT_CODE             CHAR(8),
   CLI_ID               INTEGER                          not null,
   ADR_ID               INTEGER                          not null,
   FAC_DATE             DATE,
   FAC_DAT_PMT          DATE
);

CREATE TABLE OLD_LG (
   LIF_ID               INTEGER,                         
   FAC_ID               INTEGER  not null,
   QTE                  NUMBER,
   REMISE_POURCENT      NUMBER,
   REMISE_MNT           NUMBER(8,2),
   MNT                  NUMBER(8,2),
   TAUX_TVA             NUMBER 
);

-- b) Créer le déclencheur ligne (FOR EACH ROW) TR_Facture qui supprime les lignes des factures correspondantes lorsqu'une facture est supprimée
-- c) Modifier le trigger pour qu'il insère avant chaque suppression les lignes correspondantes dans les tables OLD_FACT et OLD_LG
CREATE OR REPLACE TRIGGER TR_Facture
BEFORE DELETE ON FACTURE
FOR EACH ROW 
    BEGIN
        INSERT INTO OLD_FACT VALUES(:old.FAC_ID, :old.PMT_CODE, :old.CLI_ID, :old.ADR_ID, :old.FAC_DATE, :old.FAC_DAT_PMT); 
        INSERT INTO OLD_LG SELECT * FROM LIGNE_FACTURE WHERE FAC_ID = :old.FAC_ID;
        DELETE FROM LIGNE_FACTURE 
            WHERE FAC_ID = :old.FAC_ID;
    END;
/

DELETE FROM FACTURE WHERE FAC_ID = 1476;

-- Exercice 3
-- 1) Créer un déclencheur TR_planning qui vérifie lors de l'enregistrement d'une ligne dans la table PLANNING si la date PLN_JOUR est inférieur à la 
-- date d'aujourd'hui
CREATE OR REPLACE TRIGGER TR_planning
BEFORE INSERT OR UPDATE ON PLANNING 
FOR EACH ROW
    BEGIN 
        IF (:new.PLN_JOUR < SYSDATE) OR (:new.PLN_JOUR IS NULL) THEN
            :new.PLN_JOUR := TRUNC(SYSDATE);
        END IF;
    END;
/

INSERT INTO planning VALUES (1, TO_DATE('01/01/2020','DD/MM/YYYY'),100, 2);
INSERT INTO planning VALUES (2, NULL,100, 2);

SELECT * FROM PLANNING WHERE CHB_ID = 1 ORDER BY PLN_JOUR DESC;
SELECT * FROM PLANNING WHERE CHB_ID = 2 ORDER BY PLN_JOUR DESC;

-- 2) Compléter le déclencheur TR_planning pour qu'il vérifie également lors de l'enregistrement d'une ligne dans la table PLANNING que le nombre de
-- personnes est bien inférieur ou égal au nombre de couchages de la chambre
CREATE OR REPLACE TRIGGER TR_planning
BEFORE INSERT OR UPDATE ON PLANNING
FOR EACH ROW
DECLARE 
    v_chb_couchage CHAMBRE.chb_couchage%TYPE;
BEGIN 
    SELECT CHB_COUCHAGE INTO v_chb_couchage 
    FROM CHAMBRE
    WHERE chb_id = :new.chb_id;
    
    IF (:new.nb_pers <= v_chb_couchage) THEN
        DBMS_OUTPUT.PUT_LINE('Réservation Enregistrée');
    ELSE
        RAISE_APPLICATION_ERROR(-20001, 'Erreur');
    END IF; 
        
    IF (:new.pln_jour < SYSDATE) OR (:new.pln_jour IS NULL) THEN 
        :new.pln_jour := TRUNC(SYSDATE);
    END IF;
END;
/

-- 3) Tester avec les insertions suivantes 
INSERT INTO planning VALUES (15, NULL, 100, 15);
-- L'insertion est bien refusée

INSERT INTO planning VALUES (15, NULL, 100, 2);
-- La ligne est bien insérée

-- Exercice 4 
-- a) Mettre à jour le montant de la remise de la table LIGNE_FACTURE
UPDATE LIGNE_FACTURE 
    SET REMISE_MNT = (MNT * QTE ) * (nvl(REMISE_POURCENT,0)/100);
    
-- b) Modifier la table FACTURE pour ajouter un champ Total de type NUMBER
ALTER TABLE FACTURE 
    ADD Total Number;
    
-- c) Initialiser pour chaque facture, le champ Total
UPDATE FACTURE f
    SET Total = (SELECT ROUND(SUM((mnt * qte - remise_mnt)* (1+taux_tva/100)),2)  
                FROM LIGNE_FACTURE lf
                WHERE f.fac_id = lf.fac_id);

-- d) Créer le déclencheur TR_LG_Facture, associé à la table LIGNE_FACTURE qui met à jour le champ remise_mnt et Total
CREATE OR REPLACE TRIGGER TR_LG_FACTURE
BEFORE INSERT OR UPDATE OR DELETE ON LIGNE_FACTURE
FOR EACH ROW
BEGIN
    IF INSERTING OR UPDATING THEN
        :new.remise_mnt := :new.mnt*:new.qte*NVL(:new.remise_pourcent, 0)/100;
    END IF;
    IF UPDATING OR DELETING THEN
        UPDATE FACTURE
            SET total = total - (:old.mnt * :old.qte - :old.remise_mnt) * (1 + :old.taux_tva / 100)
            WHERE fac_id = :old.fac_id;
    END IF;
    IF INSERTING OR UPDATING THEN
        UPDATE FACTURE
        SET total = total + (:new.mnt * :new.qte - :new.remise_mnt) * (1 + :new.taux_tva / 100)
            WHERE fac_id = :new.fac_id;
    END IF;
END;
/

-- e) Tester

INSERT INTO LIGNE_FACTURE (lif_id, fac_id, qte, remise_pourcent, mnt, taux_tva) VALUES (20100, 2500, 1, 20, 10, 19.6);
INSERT INTO LIGNE_FACTURE (lif_id, fac_id, qte, remise_pourcent, mnt, taux_tva) VALUES (20101, 2500, 2, null, 20, 19.6);

UPDATE LIGNE_FACTURE
SET qte = 2
WHERE lif_id = 1317;

DELETE LIGNE_FACTURE WHERE lif_id = 1317;
SELECT * FROM FACTURE WHERE fac_id LIKE '1317';

-- Exercice 5 
-- 1) Afficher le salaire moyen d’un agent d’entretien arrondi à la centaine.
SELECT ROUND(AVG(agt_salaire), 2) AS "Salaire moyen"
FROM AGENT_ENTRETIEN;

-- 2) Faire un déclencheur TR_AGENT_V1 sur modification (INSERT, UPDATE) de la table
-- AGENT_ENTRETIEN. Il s’agit d’interdire d’affecter à un agent d’entretien un salaire inférieur à la
-- moyenne des salaires.

CREATE OR REPLACE TRIGGER TR_AGENT_V1
BEFORE INSERT OR UPDATE ON AGENT_ENTRETIEN
FOR EACH ROW
DECLARE 
    v_avg_salaire AGENT_ENTRETIEN.agt_salaire%TYPE;
BEGIN 
    SELECT ROUND(AVG(agt_salaire), 2) INTO v_avg_salaire FROM AGENT_ENTRETIEN;
    
    IF :NEW.AGT_SALAIRE < v_avg_salaire THEN
      RAISE_APPLICATION_ERROR(-20001, 'Le nouveau salaire est inférieur à la moyenne');
    END IF;
END;
/

-- 3) Tester en tentant d’affecter un salaire de 1000€ aux agents en poste. Que se passe-t-il ?
-- Désactiver le déclencheur qui ne peut donc être utilisé

UPDATE AGENT_ENTRETIEN
SET agt_salaire = 1000
WHERE agt_dpt IS NULL;

ALTER TRIGGER TR_AGENT_V1 DISABLE;

-- 4) Pour résoudre ce problème de tables mutantes, il est nécessaire de créer un déclencheur composé.
-- Créer un déclencheur composé, TR_AGENT_V2 qui vérifie, lors de l’ajout ou modification d’un agent
-- d’entretien que son salaire est bien supérieur ou égal à la moyenne des salaires des agents
CREATE OR REPLACE TRIGGER TR_AGENT_V2
FOR INSERT OR UPDATE OF agt_salaire ON AGENT_ENTRETIEN
COMPOUND TRIGGER 
G_AVG_SALAIRE AGENT_ENTRETIEN.agt_salaire%TYPE;
G_NB_AGENT INTEGER;
G_Compteur INTEGER := 0;
BEFORE STATEMENT IS
 BEGIN 
    SELECT ROUND(AVG(agt_salaire), 2) INTO G_AVG_SALAIRE FROM AGENT_ENTRETIEN;
    SELECT COUNT(agt_id) INTO G_NB_AGENT FROM AGENT_ENTRETIEN WHERE AGT_DPT IS NULL;
    DBMS_OUTPUT.PUT_LINE('Nombre d''agent : ' || G_NB_AGENT);
END BEFORE STATEMENT;
BEFORE EACH ROW IS
 BEGIN
    IF :NEW.AGT_SALAIRE < G_AVG_SALAIRE THEN
      RAISE_APPLICATION_ERROR(-20001, 'Le nouveau salaire est inférieur à la moyenne');
    ELSE 
        DBMS_OUTPUT.PUT_LINE('Ancien salaire :' || :OLD.agt_salaire);
        DBMS_OUTPUT.PUT_LINE(' Nouveau salaire : '|| :NEW.agt_salaire || CHR(10));
        G_Compteur := G_Compteur + 1;
    END IF;
    END BEFORE EACH ROW;
    AFTER STATEMENT IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Compteur : ' || G_Compteur );
    END AFTER STATEMENT;
END;
/

-- 5) Tester en augmentant de 20% les agents actuellement en poste
UPDATE AGENT_ENTRETIEN
SET agt_salaire = agt_salaire * 1.2
WHERE agt_dpt IS NULL;

    
    
    
    
    