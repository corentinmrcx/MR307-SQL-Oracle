SET SERVEROUTPUT ON;

-- Exercice 1 : 
-- 1) Utiliser un curseur explicite avec déclaration (CURSOR IS), ouverture (OPEN), parcours (FETCH) et fermeture (CLOSE) du curseur
ACCEPT s_agt_id PROMPT 'Saisir l''identifiant de l''agent'
ACCEPT s_dat_pln PROMPT 'Saisir la date du planning'
DECLARE 
    v_dat_pln PLANNING.pln_jour%TYPE;
    v_agt_id AGENT_ENTRETIEN.agt_id%TYPE := '&s_agt_id';
    v_compteur INTEGER := 0;
    v_chb_id CHAMBRE.chb_id%TYPE;
    v_chb_couchage CHAMBRE.chb_couchage%TYPE;
    
    
    CURSOR C1 IS SELECT ch.chb_id, chb_couchage 
                    FROM chambre ch
                    JOIN AGENT_ENTRETIEN agt ON (ch.AGT_ID = agt.AGT_ID)
                    JOIN PLANNING pl ON (ch.CHB_ID = pl.CHB_ID)
                        WHERE pl.pln_jour = v_dat_pln
                            AND agt.AGT_ID = v_agt_id;
BEGIN 
    SELECT agt_id INTO v_agt_id FROM AGENT_ENTRETIEN WHERE agt_id = v_agt_id;
    v_dat_pln := TO_DATE('&s_dat_pln','DD/MM/YYYY');
    OPEN C1;
    DBMS_OUTPUT.PUT_LINE('Planning du ' || v_dat_pln || ' pour l''agent ' || v_agt_id);
    LOOP 
        FETCH C1 INTO v_chb_id, v_chb_couchage;
        EXIT WHEN (C1%NOTFOUND);
        v_compteur := v_compteur + 1;
        DBMS_OUTPUT.PUT_LINE('Chambre ' || v_chb_id  || ' avec ' || v_chb_couchage || ' Couchages');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Le nombre de chambre(s) de l''agent ' || v_agt_id || ' est : ' || v_compteur);
    CLOSE C1;
        IF v_compteur = 0 THEN 
            DBMS_OUTPUT.PUT_LINE('Pas de chambre pour cet agent le ' || v_dat_pln);
        END IF;
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Agent inexistant');
END;
/

-- 2) Utiliser un curseur avec une boucle FOR
ACCEPT s_agt_id PROMPT 'METTRE AGT_ID'
ACCEPT s_dat_pln PROMPT 'DATE PLANNING'
DECLARE 
    v_dat_pln PLANNING.pln_jour%TYPE;
    v_agt_id AGENT_ENTRETIEN.agt_id%TYPE := '&s_agt_id';
    v_compteur INTEGER := 0;
    v_chb_id CHAMBRE.chb_id%TYPE;
    v_chb_couchage CHAMBRE.chb_couchage%TYPE;

BEGIN 
    SELECT agt_id INTO v_agt_id FROM AGENT_ENTRETIEN WHERE agt_id = v_agt_id;
    v_dat_pln := TO_DATE('&s_dat_pln','DD/MM/YYYY');
    DBMS_OUTPUT.PUT_LINE('Planning du ' || v_dat_pln || ' pour l''agent ' || v_agt_id);
    FOR C1 IN (SELECT ch.chb_id, chb_couchage 
               FROM chambre ch
                    JOIN AGENT_ENTRETIEN agt ON (ch.AGT_ID = agt.AGT_ID)
                    JOIN PLANNING pl ON (ch.CHB_ID = pl.CHB_ID)
               WHERE pl.pln_jour = v_dat_pln
                AND agt.AGT_ID = v_agt_id) LOOP
                
        v_compteur := v_compteur + 1;
        DBMS_OUTPUT.PUT_LINE('Chambre ' || v_chb_id  || ' avec ' || v_chb_couchage || ' Couchages');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Le nombre de chambre(s) de l''agent ' || v_agt_id || ' est : ' || v_compteur);
END;
/

-- Exercice 2 
-- 1) Ecrire un bloc PL/SQL qui affiche pour un type de téléphone et un numéro de client donnés, la liste des numéros correspondants. Afficher également le nombre de numéros récupérés. 
ACCEPT s_typ_code PROMPT 'Entrer Type de téléphone'
ACCEPT s_cli_id PROMPT 'Entrer ID client'
DECLARE 
    v_cli_id CLIENT.cli_id%TYPE := '&s_cli_id';
    v_typ_code TELEPHONE.typ_code%TYPE := UPPER('&s_typ_code');
    v_compteur INTEGER := 0;
    v_cpt_verif INTEGER := 0;
BEGIN 
    SELECT cli_id INTO v_cli_id 
    FROM CLIENT 
    WHERE cli_id = v_cli_id;
    
    v_cpt_verif := v_cpt_verif +1;
   
    SELECT typ_code INTO v_typ_code 
    FROM TYPE 
    WHERE typ_code = v_typ_code;
    
    v_cpt_verif := v_cpt_verif +1;
  
    DBMS_OUTPUT.PUT_LINE('Pour le type ' || TRIM(v_typ_code) || ' et le client ' || v_cli_id);
    FOR C2 IN (SELECT tel.typ_code, tel.tel_numero, cl.cli_id
                FROM CLIENT cl
                JOIN TELEPHONE tel ON (cl.CLI_iD = tel.CLI_ID)
                WHERE cl.cli_id = v_cli_id
                    AND tel.typ_code = v_typ_code)
    LOOP
        v_compteur := v_compteur + 1;
        DBMS_OUTPUT.PUT_LINE('N°' || v_compteur || ': ' || C2.tel_numero);
    END LOOP;
    IF v_compteur = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Pas de téléphone de type ' || TRIM(v_typ_code) ||' pour le client ' || v_cli_id);
    END IF;
    DBMS_OUTPUT.PUT_LINE(v_compteur || ' numéros correspondants');
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN 
            IF v_cpt_verif = 1 THEN 
                DBMS_OUTPUT.PUT_LINE(TRIM(v_typ_code) ||' : type de téléphone inexistant');
            ELSIF v_cpt_verif = 0 THEN 
                DBMS_OUTPUT.PUT_LINE('Client ' || v_cli_id || ' inexistant');
            END IF;
    
END;
/

-- 2) Ajouter dans la table TYPE un nouveau type de téléphone : BUR - Téléphone de Bureau
INSERT INTO TYPE
    VALUES('BUR', 'Téléphone Bureau');

-- 3) Modifier le bloc PL/SQL pour tenter de supprimer le type de téléphone dans le cas ou aucun téléphone correspondant n'a été trouvé pour le client choisi. 
ACCEPT s_typ_code PROMPT 'Entrer Type de téléphone'
ACCEPT s_cli_id PROMPT 'Entrer ID client'
DECLARE 
    v_cli_id CLIENT.cli_id%TYPE := '&s_cli_id';
    v_typ_code TELEPHONE.typ_code%TYPE := UPPER('&s_typ_code');
    v_compteur INTEGER := 0;
    v_cpt_verif INTEGER := 0;
BEGIN 
    SELECT cli_id INTO v_cli_id 
    FROM CLIENT 
    WHERE cli_id = v_cli_id;
    
    v_cpt_verif := v_cpt_verif +1;
   
    SELECT typ_code INTO v_typ_code 
    FROM TYPE 
    WHERE typ_code = v_typ_code;
    
    v_cpt_verif := v_cpt_verif +1;
  
    DBMS_OUTPUT.PUT_LINE('Pour le type ' || TRIM(v_typ_code) || ' et le client ' || v_cli_id);
    FOR C2 IN (SELECT tel.typ_code, tel.tel_numero, cl.cli_id
                FROM CLIENT cl
                JOIN TELEPHONE tel ON (cl.CLI_iD = tel.CLI_ID)
                WHERE cl.cli_id = v_cli_id
                    AND tel.typ_code = v_typ_code)
    LOOP
        v_compteur := v_compteur + 1;
        DBMS_OUTPUT.PUT_LINE('N°' || v_compteur || ': ' || C2.tel_numero);
    END LOOP;
        DBMS_OUTPUT.PUT_LINE(v_compteur || ' numéros correspondants');
    IF v_compteur = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Pas de téléphone de type ' || TRIM(v_typ_code) ||' pour le client ' || v_cli_id);
        BEGIN
            DELETE FROM TYPE WHERE typ_code = v_typ_code;
            DBMS_OUTPUT.PUT_LINE('Type ' || TRIM(v_typ_code) || ' inutilisé supprimé.');
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Type ' || TRIM(v_typ_code) || ' utilisé ne peut être supprimé.');
        END;
    END IF;
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN 
            IF v_cpt_verif = 1 THEN 
                DBMS_OUTPUT.PUT_LINE(TRIM(v_typ_code) ||' : type de téléphone inexistant');
            ELSIF v_cpt_verif = 0 THEN 
                DBMS_OUTPUT.PUT_LINE('Client ' || v_cli_id || ' inexistant');
            END IF;
    
END;
/

