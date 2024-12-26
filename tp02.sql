SET SERVEROUTPUT ON 

-- Exercice 1 : 
-- 1) a) Lister le nom des tables de votre shéma en utilisant USER_TABLES :
SELECT table_name FROM USER_TABLES;

-- b) Supprimer les tables de notre shéma :
BEGIN
    FOR tab IN (SELECT table_name FROM USER_TABLES) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE '|| tab.table_name ||' CASCADE CONSTRAINTS';
        DBMS_OUTPUT.PUT_LINE('Table '|| TAB.table_name ||' supprimée');
    END LOOP;
END;
/

-- 2) Script de création hotel.sql 
-- 3) Afin de tester les différentes syntaxes possibles, modifier les contraintes de table en contrainte de colonne chaque fois que cela est possible 
-- dans les tables TELEPHONE, ADRESSE et FACTURE
-- 4) Ajouter les requêtes de création et de suppression de la table EMAIL au bon endroit dans le script
-- 5) Ajouter les contraintes de validation
-- 6) Ajouter les contraintes de clés primaires et étrangère manquantes aux tables CHAMBRE et PLANNING
-- Script Complet : 

/*==============================================================*/
/* Nom de la base :  HOTEL                              					*/
/* Nom de SGBD :  ORACLE 			  	        	          */
/*==============================================================*/

/*==============================================================*/
/* Table : AGENT_ENTRETIEN                                     				 */
/*==============================================================*/
create table AGENT_ENTRETIEN  (
   AGT_ID           CHAR(3) 
		CONSTRAINT pk_agt PRIMARY KEY ,
   AGT_NOM          VARCHAR2(25),
   AGT_PRENOM       VARCHAR2(15),
   AGT_SX           CHAR(1) 
		CONSTRAINT chk_AGT_sx CHECK (AGT_SX IN ('1','2')),
   AGT_DNAIS	  	DATE,
   AGT_EMB          DATE 	DEFAULT SYSDATE,
   AGT_DPT          DATE,
   AGT_SALAIRE      FLOAT
)
/

/*==============================================================*/
/* Table : CHAMBRE                                              					*/
/*==============================================================*/
create table CHAMBRE  (
   CHB_ID               INTEGER
        CONSTRAINT PK_CHAMBRE PRIMARY KEY,
   CHB_COMMUNIQUE       INTEGER
        CONSTRAINT FK_CHB_COMMUNIQUE REFERENCES CHAMBRE (CHB_ID),
   AGT_ID				CHAR(3)
        CONSTRAINT FK_CHB_AGT_ID REFERENCES AGENT_ENTRETIEN (AGT_ID),
   CHB_NUMERO           SMALLINT
        CONSTRAINT CK_CHB_NUMERO CHECK (CHB_NUMERO != 13),
   CHB_ETAGE            CHAR(3)
        CONSTRAINT CK_CHB_ETAGE CHECK (UPPER(CHB_ETAGE) IN ('RDC','1ER','2E')),
   CHB_BAIN             SMALLINT
        CONSTRAINT CHB_BAIN CHECK (CHB_BAIN IN (1,0)),
   CHB_DOUCHE           SMALLINT,
   CHB_WC               SMALLINT
        CONSTRAINT CHB_WC CHECK (CHB_WC IN (1,0)),
   CHB_POSTE_TEL        CHAR(3),
   CHB_COUCHAGE         SMALLINT
)
/

/*==============================================================*/
/* Table : TITRE                                                					*/
/*==============================================================*/
create table TITRE  (
   TIT_CODE             CHAR(8) primary key,
   TIT_LIB              VARCHAR2(32)
)
/

/*==============================================================*/
/* Table : CLIENT                                               					*/
/*==============================================================*/
create table CLIENT  (
   CLI_ID               INTEGER
		constraint PK_CLIENT primary key,
   TIT_CODE             CHAR(8)
		constraint FK_CLIENT_TITRE references TITRE (TIT_CODE),
   CLI_NOM              CHAR(32),
   CLI_PRENOM           VARCHAR2(25),
   CLI_ENSEIGNE         VARCHAR2(100)
)
/


/*==============================================================*/
/* Table : TYPE                                                					 */
/*==============================================================*/
create table "TYPE"  (
   TYP_CODE             CHAR(8)   						not null
		constraint PK_TYPE primary key ,
   TYP_LIB              VARCHAR2(32)
)
/


/*==============================================================*/
/* Table : TELEPHONE                                           					 */
/*==============================================================*/
create table TELEPHONE  (
   TEL_ID               INTEGER                          not null
        constraint PK_TELEPHONE primary key,
   CLI_ID               INTEGER                          not null
        constraint FK_TEL_CLIENT references CLIENT (CLI_ID),
   TYP_CODE             CHAR(8)                          not null
        constraint FK_TEL_TYPE references "TYPE" (TYP_CODE),
   TEL_NUMERO           CHAR(20),
   TEL_LOCALISATION     VARCHAR2(20) 
)
/

/*==============================================================*/
/* Table : ADRESSE                                              					*/
/*==============================================================*/
create table ADRESSE  (
   CLI_ID               INTEGER                          not null
    CONSTRAINT FK_ADRESSE_CLIENT references CLIENT (CLI_ID),
   ADR_ID               INTEGER                          not null,
   ADR_LIGNE1           VARCHAR2(32),
   ADR_LIGNE2           VARCHAR2(32),
   ADR_LIGNE3           VARCHAR2(32),
   ADR_LIGNE4           VARCHAR2(32),
   ADR_CP               CHAR(5),
   ADR_VILLE            CHAR(32),
   
   CONSTRAINT PK_ADRESSE primary key (CLI_ID, ADR_ID)
)
/

/*==============================================================*/
/* Table : MODE_PAIEMENT                                       				 */
/*==============================================================*/
create table MODE_PAIEMENT  (
   PMT_CODE             CHAR(8)
			constraint PK_MODE_PAIEMENT primary key,
   PMT_LIB              VARCHAR2(64)
)
/

/*==============================================================*/
/* Table : FACTURE                                              					*/
/*==============================================================*/
create table FACTURE  (
   FAC_ID               INTEGER                          not null
    CONSTRAINT PK_FACTURE primary key,
   PMT_CODE             CHAR(8)
    CONSTRAINT FK_FACTURE_MODE_PAIEMENT references MODE_PAIEMENT (PMT_CODE),
   CLI_ID               INTEGER                          not null,
   ADR_ID               INTEGER                          not null,
   FAC_DATE             DATE,
   FAC_DAT_PMT          DATE,
   CONSTRAINT FK_FACTURE_ADRESSE foreign key (CLI_ID, ADR_ID)
         references ADRESSE (CLI_ID, ADR_ID),
   CONSTRAINT CK_DATES CHECK (FAC_DAT_PMT >= FAC_DATE)

)
/

/*==============================================================*/
/* Table : LIGNE_FACTURE                                       				 */
/*==============================================================*/
create table LIGNE_FACTURE  (
   LIF_ID               INTEGER                         
		constraint PK_LIGNE_FACTURE primary key,
   FAC_ID               INTEGER  not null
		constraint FK_LIGNE_FACTURE references FACTURE (FAC_ID),
   QTE                  NUMBER,
   REMISE_POURCENT      NUMBER
		CONSTRAINT CK_LIGNE_FACTURE CHECK (REMISE_POURCENT BETWEEN 0 AND 100),
   REMISE_MNT           NUMBER(8,2),
   MNT                  NUMBER(8,2),
   TAUX_TVA             NUMBER 
)
/

/*==============================================================*/
/* Table : PLANNING                                             					*/
/*==============================================================*/
drop table planning;
create table PLANNING  (
   CHB_ID               INTEGER                          not null
        CONSTRAINT FK_CHB_ID REFERENCES CHAMBRE (CHB_ID),
   PLN_JOUR             DATE                             not null,
   CLI_ID               INTEGER                          not null
		CONSTRAINT FK_PLANNING_CLIENT references CLIENT (CLI_ID),
   NB_PERS              SMALLINT,
   CONSTRAINT PK_PLANNING PRIMARY KEY (CHB_ID, PLN_JOUR)
)
/

/*==============================================================*/
/* Table : TRF_CHB                                              					*/
/*==============================================================*/
create table TRF_CHB  (
   CHB_ID               INTEGER                          not null,
   TRF_DATE_DEBUT       DATE                             not null,
   TRF_CHB_PRIX         NUMBER(8,2)
)
/

/*==============================================================*/
/* Table : EMAIL                                              					*/
/*==============================================================*/
CREATE TABLE EMAIL (
    EML_ID INTEGER NOT NULL
        CONSTRAINT PK_EMAIL_IDENTIFIANT PRIMARY KEY,
    CLI_ID INTEGER NOT NULL
        CONSTRAINT FK_CLI_ID_EMAIL REFERENCES CLIENT (CLI_ID),
    EML_ADRESSE VARCHAR(64) NOT NULL 
        CONSTRAINT CK_EML_ADRESS CHECK (EML_ADRESSE LIKE '%@%.%'),
    EML_LOCALISATION VARCHAR(20)
        CONSTRAINT CK_EML_LOCALISATION CHECK (LOWER(EML_LOCALISATION) IN ('domicile','bureau'))
)
/

/*==============================================================*/
/* Création des INDEX sur clé étrangères                        			*/
/*==============================================================*/

create index I_ADR on ADRESSE (CLI_ID ASC);

create index I_PLAN_CHB_ID on PLANNING (CHB_ID ASC);
create index I_PLAN_CLI_ID on PLANNING (CLI_ID ASC);

create index I_FACT_PMT_CODE on FACTURE (PMT_CODE ASC);
create index I_FACT_CLI_ADR on FACTURE (CLI_ID ASC, ADR_ID ASC);

create index I_LIG_FACT on LIGNE_FACTURE (FAC_ID ASC);

create index I_TEL_CLI_ID on TELEPHONE (CLI_ID ASC);
create index I_TEL_TYP_CODE on TELEPHONE (TYP_CODE ASC);

create index I_CLIENT ON CLIENT (TIT_CODE ASC);

-- Exercice 4 : 
-- 2) Ajout d'index : 
CREATE INDEX I_EMAIL ON EMAIL (CLI_ID ASC);

CREATE INDEX I_TRF_CHB ON TRF_CHB (CHB_ID ASC);
CREATE INDEX I_TRF_CHB_TRF_DATE ON TRF_CHB (TRF_DATE_DEBUT ASC);

CREATE INDEX I_CHB_COMM ON CHAMBRE (CHB_COMMUNIQUE ASC);
CREATE INDEX I_CHB_AGT ON CHAMBRE (AGT_ID ASC);

EXPLAIN plan SET statement_id ='planReq' FOR
    SELECT pln_jour, chb_id
    FROM client c 
        JOIN planning p ON (c.cli_id = p.cli_id)
    WHERE UPPER(cli_nom) = 'DUPONT'
        AND UPPER(cli_prenom)= 'ALAIN';

SELECT * FROM TABLE (DBMS_XPLAN.DISPLAY);

CREATE INDEX i_pln_client ON client (UPPER(cli_nom), UPPER(cli_prenom));

EXPLAIN plan SET statement_id ='planReq' FOR
    SELECT fac_date, cli_id
    FROM facture
    ORDER BY fac_date DESC, cli_id;

SELECT * FROM TABLE (DBMS_XPLAN.DISPLAY);

CREATE INDEX i_pln_facture ON FACTURE (fac_date DESC, cli_id ASC);

-- Exercice 5 : 
-- 1) Donner les ordres SQL assignant le privilège de lecture des tables CLIENT et ADRESSE à l'ensemble des utilisateurs 
GRANT SELECT ON CLIENT TO PUBLIC; 
GRANT SELECT ON ADRESSE TO PUBLIC;

-- Vérification :
SELECT cli_nom, adr_ville
FROM marc0237.client c 
    JOIN marc0237.adresse a ON a.cli_id = c.cli_id
ORDER BY cli_nom;

-- 2) Assigner les privilèges suivants à votre voisin : 
-- Privilège d'insertion, de suppression et de modification du nb_pers pour la table PLANNING :
CREATE VIEW v_nb_pers AS
    SELECT nb_pers FROM PLANNING; 
    
GRANT SELECT, INSERT, DELETE, UPDATE ON v_nb_pers TO peri0060;

-- Privilège d'insertion dans la table CLIENT : 
GRANT INSERT ON CLIENT TO peri0060;

-- Privilège de modification de la table CLIENT (sauf colonne cli_id)
CREATE VIEW v_client AS
    SELECT TIT_CODE, CLI_NOM, CLI_PRENOM, CLI_ENSEIGNE FROM CLIENT;
    
GRANT SELECT, UPDATE ON v_client TO peri0060;

-- Privilège de lecture de la table CLIENT en cascade (en autorisant la redistribution du privilège)
GRANT SELECT ON CLIENT TO peri0060 WITH GRANT OPTION;

-- 4) Donner un privilège à votre voisin qui lui autorise la lecture de la table AGENT_ENTRETIEN (sauf colonne AGT_SALAIRE), et uniquement pour les agents encore en poste

CREATE VIEW v_agt_etrt AS
    SELECT AGT_ID, AGT_NOM, AGT_PRENOM, AGT_SX, AGT_DNAIS, AGT_EMB, AGT_DPT 
    FROM AGENT_ENTRETIEN
    WHERE AGT_DPT IS NULL;
    
GRANT SELECT ON v_agt_etrt TO peri0060;

-- 5) Créer un rôle appelé RO_HOTEL_login et alimenter ce rôle avec les privilèges suivants :
-- Privilège de modification sur Chambre (uniquement la colonne agt_id)
-- Privilège de lecture, insertion, modification et suppression sur PLANNING et TARIF

CREATE ROLE RO_HOTEL_marc0237;

CREATE VIEW v_agt_id AS 
    SELECT AGT_ID FROM CHAMBRE;

GRANT SELECT, UPDATE ON v_agt_id TO RO_HOTEL_marc0237;
GRANT SELECT,INSERT,UPDATE,DELETE ON PLANNING TO RO_HOTEL_marc0237;
GRANT SELECT,INSERT,UPDATE,DELETE ON TARIF TO RO_HOTEL_marc0237;

-- 7) Supprimer la rôle RO_HOTEL_marc0237
DROP ROLE RO_HOTEL_marc0237;




