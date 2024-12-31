SET SERVEROUTPUT ON;

-- Exerice 1 : Ecrire un bloc PL/SQL qui affiche le nombre de chambre entretenues par un agent d'entretien dont le nom est saisi par l'utilisateur 
ACCEPT s_nom PROMPT 'Entrer un nom d''un agent' -- demande � l'utilisateur de saisir un nom d'agent dans la variable s_nom
DECLARE
    v_nomAg AGENT_ENTRETIEN.agt_nom%TYPE:= UPPER('&s_nom');
    v_nbChambres INTEGER;
BEGIN
    SELECT COUNT(ch.chb_id) INTO v_nbChambres
    FROM CHAMBRE ch
    RIGHT JOIN AGENT_ENTRETIEN ae ON (ch.AGT_ID = ae.AGT_ID)
    WHERE UPPER(ae.agt_nom) = v_nomAg
    GROUP BY ae.agt_nom;
    
    IF v_nbChambres = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Aucune chambre pour l''agent ' || v_nomAg);
    ELSE
        DBMS_OUTPUT.PUT_LINE('L''agent ' || v_nomAg || ' s''occupe de ' || v_nbChambres || ' chambre(s)');
    END IF;
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Agent ' || v_nomAG || ' inexistant' );
END;
/

-- Exercice 2 : Ecrire un bloc PL/SQL qui, étant donné le nom d'un client saisi affiche son code, son identité et la ville de son adresse principale
ACCEPT c_nom PROMPT 'Entrer le nom d''un client' -- demande le nom d'un client pour la recherche
DECLARE
    v_nomCl CLIENT.cli_nom%TYPE:= UPPER('&c_nom');
    v_pnomCl CLIENT.cli_prenom%TYPE;
    v_idCl CLIENT.cli_id%TYPE;
    v_villeCl ADRESSE.adr_ville%TYPE;
BEGIN
    SELECT cl.cli_prenom, cl.cli_id, ad.adr_ville INTO v_pnomCl, v_idCl, v_villeCl
    FROM CLIENT cl
    JOIN ADRESSE ad ON (cl.CLI_ID = ad.CLI_ID)
    WHERE UPPER(cl.cli_nom) = v_nomCl
        AND ad.ADR_ID = 1;
    
    DBMS_OUTPUT.PUT_LINE('Le client ' || v_idCl ||' '|| TRIM(v_pnomCl) || ' '|| TRIM(v_nomCl) || ' habite ' || TRIM(v_villeCl)); -- Il faut supp les espaces avec TRIM car certains champs ont bcp d'espaces (le bon vieux DIEUDONNE par exemple)
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('D�sol�, pas de client nomm� ' || TRIM(v_nomCl));
        WHEN TOO_MANY_ROWS THEN
            DBMS_OUTPUT.PUT_LINE('Attention ! Plusieurs clients pour ' || TRIM(v_nomCl));
END;
/

-- Exercice 3
-- a) Ecrire un bloc PL/SQL, qui modifie la date de départ d'un agent d'entretien
ACCEPT s_code PROMPT 'Entrer un code agent'
ACCEPT s_date PROMPT 'Entrer une date (dd/mm/yyyy)'
DECLARE
    v_code AGENT_ENTRETIEN.agt_id%TYPE := '&s_code';
    v_date AGENT_ENTRETIEN.agt_dpt%TYPE;
BEGIN
    v_date := TO_DATE ('&s_date','DD/MM/YYYY'); -- On v�rifie si la date est correcte
    SELECT agt_id INTO v_code 
    FROM AGENT_ENTRETIEN 
    WHERE agt_id = v_code;
    
    UPDATE AGENT_ENTRETIEN
    SET AGT_DPT = v_date
    WHERE AGT_ID = v_code;
    
    DBMS_OUTPUT.PUT_LINE('L''agent a été modifié');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN 
           DBMS_OUTPUT.PUT_LINE('L''agent ' || v_code || ' n''existe pas' );
        WHEN OTHERS THEN 
            DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

-- b)Ecrire un bloc PL/SQL similaire au précédent qui effectue la meme mise à jour et qui affiche les meme messages sans utiliser l'erreur NO_DATA_FOUND 
-- On utilisera cette fois l'attribut ROWCOUNT
ACCEPT s_code PROMPT 'Entrer un code agent'
ACCEPT s_date PROMPT 'Entrer une date (dd/mm/yyyy)'
DECLARE
    v_code AGENT_ENTRETIEN.agt_id%TYPE := '&s_code';
    v_date AGENT_ENTRETIEN.agt_dpt%TYPE;
BEGIN
    v_date := TO_DATE ('&s_date','DD/MM/YYYY'); -- On v�rifie si la date est correcte
    SELECT agt_id INTO v_code 
    FROM AGENT_ENTRETIEN 
    WHERE agt_id = v_code;
    
    UPDATE AGENT_ENTRETIEN
    SET AGT_DPT = v_date
    WHERE AGT_ID = v_code;
    
    IF (SQL%ROWCOUNT = 0) THEN 
        DBMS_OUTPUT.PUT_LINE('L''agent ' || v_code || ' n''existe pas' );
    ELSE
        DBMS_OUTPUT.PUT_LINE('L''agent a été modifié');
    END IF;
    EXCEPTION
        WHEN OTHERS THEN 
            DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

-- c) Ajouter à la table Agent d'entretien la contrainte qui vérifie que la date de départ est bien supérieur à la date d'embauche
ALTER TABLE AGENT_ENTRETIEN
ADD CONSTRAINT ck_dat_dpt CHECK(agt_dpt > agt_emb);

ACCEPT s_code PROMPT 'Entrer un code agent'
ACCEPT s_date PROMPT 'Entrer une date (dd/mm/yyyy)'
DECLARE
    error_date EXCEPTION;
    PRAGMA EXCEPTION_INIT(error_date, -02290);
    v_code AGENT_ENTRETIEN.agt_id%TYPE := '&s_code';
    v_date AGENT_ENTRETIEN.agt_dpt%TYPE;
BEGIN
    v_date := TO_DATE ('&s_date','DD/MM/YYYY'); -- On v�rifie si la date est correcte
        
    UPDATE AGENT_ENTRETIEN
    SET AGT_DPT = v_date
    WHERE AGT_ID = v_code;
    
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('L''agent ' || v_code || ' n''existe pas' );
    ELSE
        DBMS_OUTPUT.PUT_LINE('L''agent a été modifié');
     END IF;
    EXCEPTION   
        WHEN error_date THEN
            DBMS_OUTPUT.PUT_LINE('La date de départ de l’agent ne peut pas être inférieure à sa date d’embauche ');
        WHEN OTHERS THEN 
            DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

-- Exercice 4 
ALTER TRIGGER TR_AGENT_V1 DISABLE;
ALTER TRIGGER TR_AGENT_V2 DISABLE;

-- a) Ecrire un bloc PL/SQL qui, modifie l'agent associé à une chambre dans la table CHAMBRE 
ACCEPT s_chb_id PROMPT 'Entrer le code de la chambre'
ACCEPT s_agt_id PROMPT 'Entrer un code agent'
DECLARE
    v_chb_id CHAMBRE.chb_id%TYPE := '&s_chb_id';
    v_agt_id CHAMBRE.agt_id%TYPE := '&s_agt_id';
    error_agent EXCEPTION;
    PRAGMA EXCEPTION_INIT(error_agent, -02291);
BEGIN
    SELECT CHB_ID INTO v_chb_id
    FROM CHAMBRE
    WHERE v_chb_id = CHB_ID;
    
    UPDATE CHAMBRE
    SET AGT_ID = v_agt_id
    WHERE CHB_ID = v_chb_id;
    
    DBMS_OUTPUT.PUT_LINE('Modification effectuée : L''agent ' || v_agt_id || ' est affecté a la chambre ' || v_chb_id );
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('La chambre ' || v_chb_id || ' n''existe pas');
        WHEN error_agent THEN
            DBMS_OUTPUT.PUT_LINE('L''agent ' || v_agt_id || ' n''existe pas');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE(SQLERRM);        
END;
/

-- b) Un agent ne peut etre en charge de plus de 8 chambres
ACCEPT s_chb_id PROMPT 'Entrer le code de la chambre'
ACCEPT s_agt_id PROMPT 'Entrer un code agent'
DECLARE
    v_chb_id CHAMBRE.chb_id%TYPE := '&s_chb_id';
    v_agt_id CHAMBRE.agt_id%TYPE := '&s_agt_id';
    error_agent EXCEPTION;
    PRAGMA EXCEPTION_INIT(error_agent, -02291);
    v_nb_chb INTEGER;
    e_quota Exception;
BEGIN
    SELECT CHB_ID INTO v_chb_id
    FROM CHAMBRE
    WHERE v_chb_id = CHB_ID;
    
    SELECT COUNT(CHB_ID) INTO v_nb_chb
    FROM CHAMBRE c
        JOIN AGENT_ENTRETIEN a ON (c.AGT_ID = a.AGT_ID)
    WHERE v_agt_id = c.AGT_ID;
    
    IF v_nb_chb >= 8 THEN 
        RAISE e_quota;
    END IF;
    
    UPDATE CHAMBRE
    SET AGT_ID = v_agt_id
    WHERE CHB_ID = v_chb_id;
    
    DBMS_OUTPUT.PUT_LINE('Modification effectuée : L''agent ' || v_agt_id || ' est affecté a la chambre ' || v_chb_id );
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('La chambre ' || v_chb_id || ' n''existe pas');
        WHEN error_agent THEN
            DBMS_OUTPUT.PUT_LINE('L''agent ' || v_agt_id || ' n''existe pas');   
        WHEN e_quota THEN 
            DBMS_OUTPUT.PUT_LINE('Trop de chambre pour l''agent ' || v_agt_id || '. Modification annulée.'); 
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE(SQLERRM);       
       
END;
/

-- c) Ecrire une nouvelle version du bloc PL/SQL précédement écrit mais en gérant, cette fois de la même facon l'existence de l'agent et celle de la chambre c'est-à-dire en utilisant 
-- uniquement l'erreur NO_DATA_FOUND
ACCEPT s_chb_id PROMPT 'Entrer le code de la chambre'
ACCEPT s_agt_id PROMPT 'Entrer un code agent'
DECLARE
    v_chb_id CHAMBRE.chb_id%TYPE := '&s_chb_id';
    v_agt_id CHAMBRE.agt_id%TYPE := '&s_agt_id';
    error_agent EXCEPTION;
    PRAGMA EXCEPTION_INIT(error_agent, -02291);
    v_nb_chb INTEGER;
    e_quota Exception;
BEGIN
    SELECT AGT_ID INTO v_agt_id
    FROM AGENT_ENTRETIEN
    WHERE AGT_ID = v_agt_id;
        BEGIN
            SELECT CHB_ID INTO v_chb_id
            FROM CHAMBRE
            WHERE v_chb_id = CHB_ID;
        
            SELECT COUNT(CHB_ID) INTO v_nb_chb
            FROM CHAMBRE c
                JOIN AGENT_ENTRETIEN a ON (c.AGT_ID = a.AGT_ID)
            WHERE v_agt_id = c.AGT_ID;
            
            IF v_nb_chb >= 7 THEN 
                RAISE e_quota;
            END IF;
            
            UPDATE CHAMBRE
            SET AGT_ID = v_agt_id
            WHERE CHB_ID = v_chb_id;
            
            DBMS_OUTPUT.PUT_LINE('Modification effectuée : L''agent ' || v_agt_id || ' est affecté a la chambre ' || v_chb_id );
        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('La chambre ' || v_chb_id || ' n''existe pas');
            WHEN e_quota THEN 
                DBMS_OUTPUT.PUT_LINE('Trop de chambre pour l''agent ' || v_agt_id || '. Modification annulée.'); 
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE(SQLERRM);       
    END;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('L''agent ' || v_agt_id || 'n''existe pas.'); 
    END;
/








