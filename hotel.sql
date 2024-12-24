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
   CHB_ID               INTEGER,
   CHB_COMMUNIQUE       INTEGER,
   AGT_ID				CHAR(3),
   CHB_NUMERO           SMALLINT,
   CHB_ETAGE            CHAR(3),
   CHB_BAIN             SMALLINT,
   CHB_DOUCHE           SMALLINT,
   CHB_WC               SMALLINT,
   CHB_POSTE_TEL        CHAR(3),
   CHB_COUCHAGE         SMALLINT
)
/

/*==============================================================*/
/* Table : TITRE                                                					*/
/*==============================================================*/
create table TITRE (
   TIT_CODE             CHAR(8) constraint PK_TITRE primary key,
   TIT_LIB              VARCHAR2(32)
);
/

/*==============================================================*/
/* Table : CLIENT                                               					*/
/*==============================================================*/
create table CLIENT  (
   CLI_ID               INTEGER constraint PK_CLIENT primary key,
   TIT_CODE             CHAR(8) constraint FK_CLIENT_TITRE references TITRE (TIT_CODE),
   CLI_NOM              CHAR(32),
   CLI_PRENOM           VARCHAR2(25),
   CLI_ENSEIGNE         VARCHAR2(100)
)
/

/*==============================================================*/
/* Table : TELEPHONE                                           					 */
/*==============================================================*/
create table TELEPHONE  (
   TEL_ID               INTEGER                          not null,
   CLI_ID               INTEGER                          not null,
   TYP_CODE             CHAR(8)                          not null,
   TEL_NUMERO           CHAR(20),
   TEL_LOCALISATION     VARCHAR2(20),
   constraint PK_TELEPHONE primary key (TEL_ID),
   constraint FK_TEL_CLIENT foreign key (CLI_ID) references CLIENT (CLI_ID),
   constraint FK_TEL_TYPE foreign key (TYP_CODE) references "TYPE" (TYP_CODE)
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
/* Table : ADRESSE                                              					*/
/*==============================================================*/
create table ADRESSE  (
   CLI_ID               INTEGER                          not null,
   ADR_ID               INTEGER                          not null,
   ADR_LIGNE1           VARCHAR2(32),
   ADR_LIGNE2           VARCHAR2(32),
   ADR_LIGNE3           VARCHAR2(32),
   ADR_LIGNE4           VARCHAR2(32),
   ADR_CP               CHAR(5),
   ADR_VILLE            CHAR(32),
   CONSTRAINT PK_ADRESSE primary key (CLI_ID, ADR_ID),
   CONSTRAINT FK_ADRESSE_CLIENT foreign key (CLI_ID) references CLIENT (CLI_ID)
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
   FAC_ID               INTEGER                          not null,
   PMT_CODE             CHAR(8),
   CLI_ID               INTEGER                          not null,
   ADR_ID               INTEGER                          not null,
   FAC_DATE             DATE,
   FAC_DAT_PMT          DATE,
   CONSTRAINT PK_FACTURE primary key (FAC_ID),
   CONSTRAINT FK_FACTURE_MODE_PAIEMENT foreign key (PMT_CODE)
         references MODE_PAIEMENT (PMT_CODE),
   CONSTRAINT FK_FACTURE_ADRESSE foreign key (CLI_ID, ADR_ID)
         references ADRESSE (CLI_ID, ADR_ID)
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
create table PLANNING  (
   CHB_ID               INTEGER                          not null,
   PLN_JOUR             DATE                             not null,
   CLI_ID               INTEGER                          not null
		CONSTRAINT FK_PLANNING_CLIENT references CLIENT (CLI_ID),
   NB_PERS              SMALLINT
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




