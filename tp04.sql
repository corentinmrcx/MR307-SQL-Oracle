SET SERVEROUTPUT ON; 

-- Exercice 1 
-- a) Créer un déclencheur qui affiche un message chaque fois qu'un utilisateur crée un objet dans son schéma. 
CREATE OR REPLACE TRIGGER TR_CREATE 
AFTER CREATE ON SCHEMA
BEGIN 
    DBMS_OUTPUT.PUT_LINE(ORA_LOGIN_USER || ', vous venez de créer l''objet ' || ORA_DICT_OBJ_NAME || ' de type ' || ORA_DICT_OBJ_TYPE);
END;
/

-- b) Tester le déclencheur 
CREATE TABLE test (chp1 INTEGER);

CREATE INDEX I_test ON test(chp1);

-- c) Modifier le déclencheur pour qu'il affiche un message chaque fois qu'un utilisateur crée mais aussi supprime ou modifie un objet dans son schéma
CREATE OR REPLACE TRIGGER TR_CREATE
AFTER CREATE OR ALTER OR DROP ON SCHEMA
BEGIN
    if (ORA_SYSEVENT = 'CREATE') THEN 
        DBMS_OUTPUT.PUT_LINE(ORA_LOGIN_USER || ', vous venez de créer l''objet ' || ORA_DICT_OBJ_NAME || ' de type ' || ORA_DICT_OBJ_TYPE);
    elsif (ORA_SYSEVENT = 'ALTER') THEN 
        DBMS_OUTPUT.PUT_LINE(ORA_LOGIN_USER || ', vous venez de modifier l''objet ' || ORA_DICT_OBJ_NAME || ' de type ' || ORA_DICT_OBJ_TYPE);
    elsif (ORA_SYSEVENT = 'DROP') THEN
        DBMS_OUTPUT.PUT_LINE(ORA_LOGIN_USER || ', vous venez de supprimé l''objet ' || ORA_DICT_OBJ_NAME || ' de type ' || ORA_DICT_OBJ_TYPE);
    end if;
END;
/

-- d) Tester le déclencheur 
alter table test add chp2 INTEGER;

drop table test;

-- Exercice 2 
-- a) Créer une table TRACE_LOG composée de 3 champs (sans clé primaire) 
CREATE TABLE TRACE_LOG (
    DAT_EV DATE,
    USER_LOG VARCHAR2(15),
    TP_LOG VARCHAR2(12)
);

-- b) Ajouter une contrainte sur TP_LOG pour n'autoriser que les valeurs "Connexion" et "Deconnexion"
ALTER TABLE TRACE_LOG
ADD CONSTRAINT CK_TP_LOG CHECK(LOWER(TP_LOG) IN ('connexion','dconnexion'));

-- c) Créer les déclencheurs permettant la mise à jour de la table TRACE_LOG à chaque connexion et à chaque déconnexion sur votre shéma
CREATE OR REPLACE TRIGGER TR_LOGON
AFTER LOGON ON SCHEMA
BEGIN 
    INSERT INTO TRACE_LOG VALUES (SYSDATE, ORA_LOGIN_USER, 'Connexion');
END;
/

CREATE OR REPLACE TRIGGER TR_LOGOFF
BEFORE LOGOFF ON SCHEMA
BEGIN 
    INSERT INTO TRACE_LOG VALUES (SYSDATE, ORA_LOGIN_USER, 'Déconnexion');
END;
/

-- Exercice 3 
-- a) Créer une vue qui contient les clients avec leur numéro de portable dont l'adresse principale est située dans la ville de LAON. 
CREATE OR REPLACE VIEW VU_CLT_LAON AS
SELECT cli_nom, cli_prenom, adr_ligne1, tel_numero, typ_code
FROM CLIENT cl
    JOIN ADRESSE ad ON (cl.cli_id = ad.cli_id)
    LEFT JOIN TELEPHONE tel ON (cl.CLI_ID = tel.CLI_ID and typ_code = 'GSM')
WHERE UPPER(adr_ville) = 'LAON';

SELECT * FROM VU_CLT_LAON;

INSERT INTO TELEPHONE VALUES(400,(SELECT cli_id FROM client where UPPER(cli_nom) = 'MONTEIL'),'GSM','07-05-06-08-99','portable');

-- b) Tenter d'insérer le nouveau client suivant via la vue VU_CLT_LAON
INSERT INTO VU_CLT_LAON (cli_nom, cli_prenom, adr_ligne1, tel_numero)
    VALUES ('HAZARD','Augustin','4 rue du cheval Blanc','06-12-46-95-58');

-- c) Créer un déclencheur INSTEAD_CLT_LAON qui remplace une insertion d'un client dans la vue CLIENT_LAON par des insertions dans les tables CLIENT, TELEPHONE et ADRESSE
CREATE OR REPLACE TRIGGER INSTEAD_CLT_LAON
INSTEAD OF INSERT ON VU_CLT_LAON
FOR EACH ROW 
DECLARE 
    v_nouv_cli_id CLIENT.CLI_ID%TYPE;
    v_nouv_tel_id TELEPHONE.TEL_ID%TYPE;
    v_typ_code TELEPHONE.typ_code%TYPE := 'TEL';
    v_tel_loca TELEPHONE.tel_localisation%TYPE := null;
BEGIN 
    SELECT MAX(CLI_ID)+1  INTO v_nouv_cli_id FROM CLIENT; -- rcup du dernier cli_id + 1
    SELECT MAX(TEL_ID)+1  INTO v_nouv_tel_id FROM TELEPHONE; -- rcup du dernier cli_id + 1
    
    IF :new.tel_numero IN ('06%','07%') THEN
        v_typ_code := 'GSM';
        v_tel_loca := 'portable';
    END IF;
    
    INSERT INTO CLIENT (cli_id, cli_nom, cli_prenom) 
        VALUES (v_nouv_cli_id, :new.cli_nom, :new.cli_prenom);
    
    INSERT INTO ADRESSE (cli_id, adr_id, adr_ligne1, adr_cp, adr_ville) 
        VALUES (v_nouv_cli_id, 1, :new.adr_ligne1, '02000', 'LAON');
    
    INSERT INTO TELEPHONE (tel_id, cli_id, typ_code, tel_numero, tel_localisation)
        VALUES (v_nouv_tel_id, v_nouv_cli_id, v_typ_code, :new.tel_numero, v_tel_loca); 
END;
/

INSERT INTO VU_CLT_LAON (cli_nom, cli_prenom, adr_ligne1, tel_numero)
    VALUES('MARTIN','Noah','12 rue Joffre', '03-26-85-74-11');







