SET SERVEROUTPUT ON;

-- Exercice 1 : 
-- a) Ecrire la procédure PL/SQL clientville (p_ville IN...) qui, selon la ville p_ville passée en paramètre,
-- affiche la liste des clients de cette ville (s’il y en a)

CREATE OR REPLACE PROCEDURE  clientville
    (p_ville IN adresse.adr_ville%type) 
IS
    v_compteur INTEGER := 0;
BEGIN 
    DBMS_OUTPUT.PUT_LINE('Ville : ' || p_ville);
    DBMS_OUTPUT.PUT_LINE('-----------------');
    FOR cli IN (SELECT cli_nom, cli_prenom 
                FROM client cl 
                JOIN adresse ad ON (cl.CLI_ID = ad.CLI_ID)
                WHERE UPPER(adr_ville) = UPPER(p_ville)
        ) LOOP 
            v_compteur := v_compteur + 1;
            DBMS_OUTPUT.PUT_LINE(cli.cli_nom || ' ' || cli.cli_prenom);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Nb de clients de ' || p_ville || ' est : ' || v_compteur);
END;
/

EXEC clientville('Reims');

-- b) Utiliser la procédure dans un nouveau bloc PL/SQL (anonyme) pour chaque ville de la Marne (trouvée
-- dans la table ADRESSE)

DECLARE 
    CURSOR c_villes IS 
        SELECT DISTINCT adr_ville
        FROM adresse 
        WHERE adr_cp LIKE ('51%');
        
    v_ville adresse.adr_ville%type;
BEGIN
    OPEN c_villes;
    LOOP
        FETCH c_villes INTO v_ville;
        EXIT WHEN c_villes%NOTFOUND;
        
        clientville(v_ville);
    END LOOP;
    CLOSE c_villes;
END;
/

-- Exercice 2 :
-- a) Ecrire la procédure PL/SQL agt_chb (p_num IN..., p_nom OUT..., p_prenom OUT...) qui selon
-- l’identifiant p_num d’une chambre (IN), renvoie dans les paramètres de sortie (OUT) le nom et le prénom
-- de l’agent en charge de cette chambre.

CREATE OR REPLACE PROCEDURE agt_chb 
    (
    p_num IN chambre.chb_id%type,
    p_nom OUT agent_entretien.agt_nom%type,
    p_prenom OUT agent_entretien.agt_prenom%type
    ) 
    IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM chambre
    WHERE chb_id = p_num;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'ERREUR : Chambre inexistante');
    END IF;
    
    SELECT agt_nom, agt_prenom INTO p_nom, p_prenom
    FROM agent_entretien agt
        JOIN chambre chb ON (agt.agt_id = chb.agt_id)
    WHERE chb_id = p_num;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'ERREUR : Pas d''agent pour cette chambre');
END agt_chb;
/


-- b) Ecrire un bloc PL/SQL pour tester la procédure sur une chambre dont l’identifiant sera saisi par
-- l’utilisateur et qui affiche les résultats correspondants.
-- Utiliser PRAGMA EXCEPTION_INIT pour gérer le cas d’une chambre inexistante et afficher le message
-- d’erreur correspondant.

ACCEPT s_chb_id PROMPT 'Saisir l''identifiant d''une chambre'
DECLARE
    v_chb_id chambre.chb_id%TYPE;  
    v_nom agent_entretien.agt_nom%TYPE; 
    v_prenom agent_entretien.agt_prenom%TYPE; 

    chambre_inexistante EXCEPTION;
    PRAGMA EXCEPTION_INIT(chambre_inexistante, -20001);

BEGIN
    v_chb_id := '&s_chb_id'; 
    agt_chb(v_chb_id, v_nom, v_prenom);
    DBMS_OUTPUT.PUT_LINE(v_nom || ' ' || v_prenom || ' est en charge de la chambre ' || v_chb_id);

EXCEPTION
    WHEN chambre_inexistante THEN
        DBMS_OUTPUT.PUT_LINE('ERREUR : Chambre ' || v_chb_id || ' inexistante');
END;
/

-- c) Exécuter la procédure dans un bloc PL/SQL pour toutes les chambres réservées (présentes dans la table
-- planning) à un étage et une date saisis par l’utilisateur.
-- Gérer l’erreur utilisateur d’un étage incorrect (« RDC », « 1er » ou « 2e ») et l’erreur de date (date
-- incorrecte)

ACCEPT p_etage PROMPT 'Saisir l''etage des chambres'
ACCEPT p_date PROMPT 'Saisir la date'
DECLARE
    v_etage chambre.chb_etage%type;
    v_date planning.pln_jour%type;                      
    v_chb_id chambre.chb_id%TYPE;     
    v_nom agent_entretien.agt_nom%TYPE;
    v_prenom agent_entretien.agt_prenom%TYPE; 

    CURSOR c_chambres IS
        SELECT DISTINCT chb.chb_id
        FROM planning pl
            JOIN chambre chb ON pl.chb_id = chb.chb_id
        WHERE chb.chb_etage = v_etage
            AND pl.pln_jour = v_date;

    invalid_etage EXCEPTION;
    invalid_date EXCEPTION;

    PRAGMA EXCEPTION_INIT(invalid_etage, -20003);
    PRAGMA EXCEPTION_INIT(invalid_date, -20004);

    v_chambre_count NUMBER := 0;

BEGIN
    v_etage := '&p_etage'; 
    v_date := TO_DATE('&p_date', 'DD/MM/YYYY');

    IF v_etage NOT IN ('RDC', '1er', '2e') THEN
        RAISE invalid_etage;
    END IF;

    IF v_date IS NULL THEN
        RAISE invalid_date;
    END IF;

    DBMS_OUTPUT.PUT_LINE('-------PERSONNEL ATTENDU le ' || TO_CHAR(v_date, 'DD/MM/YYYY') ||
                         ' A l''ETAGE : ' || v_etage || '--------');

    OPEN c_chambres;
    LOOP
        FETCH c_chambres INTO v_chb_id;
        EXIT WHEN c_chambres%NOTFOUND;

        BEGIN
            agt_chb(v_chb_id, v_nom, v_prenom);
            DBMS_OUTPUT.PUT_LINE(v_nom || ' ' || v_prenom || ' pour la chambre ' || v_chb_id);
            v_chambre_count := v_chambre_count + 1;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Erreur pour la chambre ' || v_chb_id || ': ' || SQLERRM);
        END;
    END LOOP;
    CLOSE c_chambres;

    IF v_chambre_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Pas de chambre reserve le ' || TO_CHAR(v_date, 'DD/MM/YYYY') || ' à l''etage ' || v_etage);
    END IF;

EXCEPTION
    WHEN invalid_etage THEN
        DBMS_OUTPUT.PUT_LINE('Ce n''est pas un étage valide');
    WHEN invalid_date THEN
        DBMS_OUTPUT.PUT_LINE('La date saisie est incorrecte');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur inconnue : ' || SQLERRM);
END;
/

-- Exercice 3 :
-- a) Créer une fonction idPlus1( ) qui retourne l’identifiant max + 1 de la table Client

CREATE OR REPLACE FUNCTION idPlus1 RETURN NUMBER
IS 
    v_id_max client.cli_id%TYPE;
BEGIN 
    select max(cli_id) into v_id_max
    from client;
    
    v_id_max := v_id_max + 1;
    
    return (v_id_max);
END;
/

-- Tester la fonction en l’utilisant dans un SELECT ... FROM DUAL ;
SELECT idPlus1 FROM DUAL;

-- Tester la fonction en insérant un nouveau client.
insert into client (cli_id, cli_nom, cli_prenom) values (idPlus1, 'TUTIN', 'Michel');

-- Vérifier en affichant les clients dont le cli_id est supérieur à 100
select * from client where cli_id >= 100;

-- b) Créer une fonction EstEnRegle(p_cli_id...) qui renvoie vrai ou faux selon que le client a une
-- facture impayée ou non (facture qui n’a pas de date de paiement).
CREATE OR REPLACE FUNCTION EstEnRegle(p_cli_id IN client.cli_id%TYPE) RETURN BOOLEAN
IS 
    v_count_facture NUMBER:= 0;
BEGIN
    SELECT COUNT(fac_id) INTO v_count_facture
    FROM FACTURE
    WHERE cli_id = p_cli_id
     AND fac_dat_pmt IS NULL;
     
    IF v_count_facture > 0 THEN
        RETURN False;
    ELSE
        RETURN True;
    END IF;
END;
/

-- c) Créer une fonction Existe(p_cli_id ...) qui renvoie vrai ou faux selon que le client existe ou non.
CREATE OR REPLACE FUNCTION Existe(p_cli_id CLIENT.cli_id%TYPE) RETURN BOOLEAN
IS
    v_count_client NUMBER := 0;
BEGIN 
    SELECT COUNT(cli_id) INTO v_count_client
    FROM CLIENT
    WHERE cli_id = p_cli_id;
    
    IF v_count_client = 0 THEN 
        RETURN False;
    ELSE
        RETURN True;
    END IF;
END;
/

-- d) Tester les fonctions en créant un bloc PLSQL qui affiche un message selon que le client dont le
-- numéro est saisi par l’utilisateur existe ou non, et est en règle ou non.
ACCEPT s_client_code PROMPT 'Entrez un numéro client'
DECLARE
    v_cli_id client.cli_id%type := '&s_client_code';
BEGIN
    IF Existe(v_cli_id) THEN
        IF EstEnRegle(v_cli_id) THEN
            DBMS_OUTPUT.PUT_LINE('Le client '||v_cli_id||' est en règle');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Le client '||v_cli_id||' n’a pas payé ses factures');
        END IF;
    ELSE
        DBMS_OUTPUT.PUT_LINE('Le client n’existe pas');
    END IF;
END;
/

-- Exercice 4 :
-- a) Créer la fonction table_existe (nom_table IN VARCHAR2) qui renvoie VRAI (un booléen) lorsque la table dont le nom passé en paramètre existe et qui renvoie FAUX sinon
CREATE OR REPLACE FUNCTION table_existe (nom_table IN VARCHAR2) RETURN BOOLEAN
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(TABLE_NAME) INTO v_count
    FROM USER_TABLES
    WHERE TABLE_NAME = UPPER(nom_table);
    
    IF v_count = 0 THEN
        RETURN False;
    ELSE
        RETURN TRUE;
    END IF;
END;
/

-- b) Ecrire un bloc PL/SQL qui selon le nom de la table saisi par l’utilisateur affiche un message correspondant
ACCEPT s_table PROMPT 'Entrez un nom de table'
DECLARE
    v_nom_table VARCHAR2(30) := UPPER('&s_table');
BEGIN
    IF table_existe(v_nom_table) THEN
        DBMS_OUTPUT.PUT_LINE('La table '||v_nom_table||' existe');
    ELSE
        DBMS_OUTPUT.PUT_LINE('La table '||v_nom_table||' n’existe pas');
    END IF;
END;
/




