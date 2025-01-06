-- Exercice 1 : 
-- a) Lancer le script fourni spectacle.sql qui crée les deux tables et insère quelques données dans les tables.
-- b) Modifier la procédure suppPers pour qu’elle affiche « Personne inexistante » si tel est le cas.
CREATE OR REPLACE PROCEDURE SuppPers(p_idPers personne.idPers%TYPE)
IS
BEGIN
    DELETE FROM personne 
    WHERE idPers = p_idPers; 
    
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE ('Personne inexistante');
    ELSE
        DBMS_OUTPUT.PUT_LINE ('personne '|| p_idPers || ' supprimée');
    END IF;
END;
/

-- c)Tester (on utilise la commande EXECUTE : EXEC infoPers(1) par exemple) :
-- - Afficher les infos de la personne 1
-- - Tenter de supprimer la personne 3
-- - Afficher les informations du spectacle 2
-- - Afficher les informations du spectacle 3 

EXECUTE infoPers(1);
EXECUTE suppPers(3);
EXECUTE infoSpect(2);
EXECUTE infoSpect(3);

-- Exercice 2
-- a) Ecrire la fonction genIdPers qui renvoie un nouveau numéro de personne à partir du nb de personnes
-- déjà présents dans la table (+1)

CREATE OR REPLACE FUNCTION genIdPers RETURN NUMBER
IS 
    v_numPers personne.idPers%type;
BEGIN 
    SELECT MAX(idPers)+1 INTO v_numPers
    FROM personne;
    
    RETURN v_numPers;
END genIdPers;
/

/* b) Écrire les procédures suivantes :
        - ajoutPers (p_nom, p_solde) qui ajoute (INSERT) une personne dans la table PERSONNE.
            On utilisera la fonction genIdPers().
            Afficher un message indiquant le nouvel identifiant utilisé : « Personne 3 ajoutée ».
            Tester en ajoutant la personne suivante : Lohan dont le solde est 200 puis supprimer la en utilisant la
            procédure suppPers.
        - majSpect (p_idSpect, p_nbResa) qui met à jour (UPDATE) le nombre de places disponibles
            du spectacle passé en paramètre en le diminuant du nombre de places réservées passé en paramètre.
            Afficher le nombre de places restant.
*/

CREATE OR REPLACE PROCEDURE ajoutPers(p_nom IN personne.nom%type, p_solde IN personne.solde%type)
IS 
    v_idNewPers personne.idPers%type := genIdPers();
BEGIN
    INSERT INTO personne VALUES (v_idNewPers, p_nom, p_solde);
    DBMS_OUTPUT.PUT_LINE('Personne ' || v_idNewPers || ' ajoute');
END;
/

EXEC ajoutPers('Lohan', 200);

EXEC suppPers(3);

CREATE OR REPLACE PROCEDURE majSpect(p_idSpect IN spectacle.idSPect%type, p_nbResa IN spectacle.nbPlacesLibres%type)
IS 
    v_nbPlacesRestantes spectacle.nbPlacesLibres%type;
BEGIN
    SELECT nbPlacesLibres - p_nbResa INTO v_nbPlacesRestantes
    FROM spectacle
    WHERE idSpect = p_idSpect;
    
    UPDATE spectacle
    SET nbPlacesLibres = nbPlacesLibres - p_nbResa
    WHERE idSpect = p_idSpect
    RETURNING nbPlacesLibres INTO v_nbPlacesRestantes;
    
    DBMS_OUTPUT.PUT_LINE('Nombre de places restantes pour ce spectacles : ' || v_nbPlacesRestantes);
END;
/

/* c) Écrire la fonction suivante :
        - nbResa (p_idPers, p_idSpect) qui renvoie le nombre total de places réservées par la
            personne pour le spectacle donné. 
*/

SELECT * FROM PERSONNE;
SELECT * FROM SPECTACLE;
SELECT * FROM RESERVATION;

CREATE OR REPLACE FUNCTION nbResa(p_idPers IN personne.idPers%type, p_idSpect IN spectacle.idSpect%type) RETURN NUMBER
IS 
    v_nbPlacesReservees reservation.nbPlacesResa%type;
BEGIN 
    SELECT nbPlacesResa INTO v_nbPlacesReservees
    FROM RESERVATION res
    WHERE idPers = p_idPers
    AND idSpect = p_idSpect;
    
    RETURN v_nbPlacesReservees;
END;
/

/*
d) Écrire la procédure suivante :
    - majPers (p_idPpers, p_idSpect, p_nbResa) qui
        - Vérifie que le nombre de places disponibles du spectacle est suffisant (Exception avec
        affichage message « nb de places disponibles insuffisant »)
        - Vérifie que le solde de la personne est suffisant pour le nombre de places désiré en fonction
        du tarif du spectacle (Exception avec affichage message « solde insuffisant »)
        - Modifie, le cas échéant, le solde et insère une nouvelle réservation avec le nombre de places
        réservées pour la personne concernée à la date du jour.
        - Affiche le solde de la personne et le nombre total de places réservées pour le spectacle donné
        (utiliser la fonction précédemment créée).
*/

CREATE OR REPLACE PROCEDURE majPers(
    p_idPers IN personne.idPers%type, 
    p_idSpect IN spectacle.idSpect%type, 
    p_nbResa IN spectacle.nbPlacesLibres%type)
IS
    v_nbPlacesRestantes spectacle.nbPlacesLibres%type;
    v_tarif spectacle.tarif%type;
    v_solde personne.solde%type;
    v_totalTarif NUMBER;
    v_nbResaExistantes reservation.nbPlacesResa%type;
BEGIN
    SELECT nbPlacesLibres INTO v_nbPlacesRestantes
    FROM spectacle
    WHERE idSpect = p_idSpect;

    IF v_nbPlacesRestantes < p_nbResa THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nombre de places disponibles insuffisant');
    END IF;

    SELECT solde INTO v_solde
    FROM personne
    WHERE idPers = p_idPers;

    SELECT tarif INTO v_tarif
    FROM spectacle
    WHERE idSpect = p_idSpect;
    
    v_totalTarif := p_nbResa * v_tarif;

    IF v_solde < v_totalTarif THEN
        RAISE_APPLICATION_ERROR(-20002, 'Solde insuffisant');
    END IF;

    UPDATE personne
    SET solde = solde - v_totalTarif
    WHERE idPers = p_idPers;

    INSERT INTO reservation (idPers, idSpect, nbPlacesResa, dateResa)
    VALUES (p_idPers, p_idSpect, p_nbResa, SYSDATE);

    UPDATE spectacle
    SET nbPlacesLibres = nbPlacesLibres - p_nbResa
    WHERE idSpect = p_idSpect;

    DBMS_OUTPUT.PUT_LINE('Solde restant pour la personne ' || p_idPers || ' : ' || (v_solde - v_totalTarif));
    DBMS_OUTPUT.PUT_LINE('Nombre de places rserves : ' || p_nbResa);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Donnes non trouves pour cette personne ou ce spectacle');
END majPers;
/

-- e) Tester les procédures

EXEC ajoutPers('Axel',10);
EXEC infoPers(3);
EXEC majPers (p_idPers => 3, p_idSpect => 1, p_nbResa =>2);
EXEC majPers(p_idPers => 1, p_idSpect => 1, p_nbResa=> 2);
EXEC infoSpect(1);
EXEC infoPers(1);
EXEC majPers(p_idPers => 1, p_idSpect => 2, p_nbResa=> 5);
EXEC infoSpect(2);

-- Exercice 3 : 
-- a) Création du package
CREATE OR REPLACE PACKAGE gestionSpec AS
    PROCEDURE infoPers(p_idPers IN personne.idPers%TYPE);
    PROCEDURE infoSpect(p_idSpect IN spectacle.idSpect%TYPE);
    PROCEDURE suppPers(p_idPers IN personne.idPers%TYPE);
    PROCEDURE ajoutPers(p_nom IN personne.nom%TYPE, p_solde IN personne.solde%TYPE);
    PROCEDURE majSpect(p_idSpect IN spectacle.idSpect%TYPE, p_nbResa IN spectacle.nbPlacesLibres%TYPE);
    PROCEDURE majPers(p_idPers IN personne.idPers%TYPE, p_idSpect IN spectacle.idSpect%TYPE, p_nbResa IN reservation.nbPlacesResa%TYPE);
END gestionSpec;
/

CREATE OR REPLACE PACKAGE BODY gestionSpec AS

    FUNCTION genIdPers RETURN NUMBER IS
        v_numPers personne.idPers%TYPE;
    BEGIN
        SELECT MAX(idPers) + 1 INTO v_numPers
        FROM personne;
        RETURN v_numPers;
    END genIdPers;

    procedure infoPers (p_idPers IN personne.idPers%TYPE)
        IS
        v_nom 			personne.nom%TYPE;
        v_nbPlacesResa 	reservation.nbPlacesResa%TYPE;
        v_solde 		personne.solde%TYPE;
        
        BEGIN
            SELECT nom, solde INTO v_nom,  v_solde
            FROM personne
            WHERE idPers = p_idPers; 
            DBMS_OUTPUT.PUT_LINE (v_nom||' : '||' solde : '||v_solde || ' €');
        
            FOR c IN (SELECT titre, nbPlacesResa 
                        FROM spectacle s JOIN reservation r ON (r.idSpect = s.idSpect)
                        WHERE r.idPers = p_idPers)
            LOOP 
                DBMS_OUTPUT.PUT_LINE (c.nbPlacesResa || ' place(s) réservée(s) pour '||c.titre);
            END LOOP; 
        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE ('personne inexistante');
    END infopers;

    procedure infoSpect (p_idSpect IN spectacle.idSpect%TYPE)
        IS
        v_titre 			spectacle.titre%TYPE;
        v_nbPlacesLibres    spectacle.nbPlacesLibres%TYPE;
        
        BEGIN
            SELECT titre, nbPlacesLibres INTO v_titre, v_nbPlacesLibres
            FROM spectacle
            WHERE idSpect = p_idSpect; 
            DBMS_OUTPUT.PUT_LINE ('Le spectacle ' || v_titre||' propose encore '||v_nbPlacesLibres ||' place(s)');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE ('spectacle inexistant');
    END infoSpect;

    PROCEDURE suppPers(p_idPers IN personne.idPers%TYPE) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM personne
        WHERE idPers = p_idPers;

        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Personne inexistante');
        ELSE
            DELETE FROM personne WHERE idPers = p_idPers;
            DBMS_OUTPUT.PUT_LINE('Personne ' || p_idPers || ' supprime');
        END IF;
    END suppPers;

    PROCEDURE ajoutPers(p_nom IN personne.nom%TYPE, p_solde IN personne.solde%TYPE) IS
        v_idNewPers personne.idPers%TYPE := genIdPers();
    BEGIN
        INSERT INTO personne VALUES (v_idNewPers, p_nom, p_solde);
        DBMS_OUTPUT.PUT_LINE('Personne ' || v_idNewPers || ' ajoute');
    END ajoutPers;

    PROCEDURE majSpect(p_idSpect IN spectacle.idSpect%TYPE, p_nbResa IN spectacle.nbPlacesLibres%TYPE) IS
        v_nbPlacesRestantes spectacle.nbPlacesLibres%TYPE;
    BEGIN
        SELECT nbPlacesLibres - p_nbResa INTO v_nbPlacesRestantes
        FROM spectacle
        WHERE idSpect = p_idSpect;

        IF v_nbPlacesRestantes < 0 THEN
            DBMS_OUTPUT.PUT_LINE('Nombre de places disponibles insuffisant');
        ELSE
            UPDATE spectacle
            SET nbPlacesLibres = nbPlacesLibres - p_nbResa
            WHERE idSpect = p_idSpect;
            DBMS_OUTPUT.PUT_LINE('Places mises  jour. Places restantes: ' || v_nbPlacesRestantes);
        END IF;
    END majSpect;

    PROCEDURE majPers(p_idPers IN personne.idPers%type, p_idSpect IN spectacle.idSpect%type, p_nbResa IN spectacle.nbPlacesLibres%type) IS
            v_nbPlacesRestantes spectacle.nbPlacesLibres%type;
            v_tarif spectacle.tarif%type;
            v_solde personne.solde%type;
            v_totalTarif NUMBER;
            v_nbResaExistantes reservation.nbPlacesResa%type;
        BEGIN
            SELECT nbPlacesLibres INTO v_nbPlacesRestantes
            FROM spectacle
            WHERE idSpect = p_idSpect;
        
            IF v_nbPlacesRestantes < p_nbResa THEN
                RAISE_APPLICATION_ERROR(-20001, 'Nombre de places disponibles insuffisant');
            END IF;
        
            SELECT solde INTO v_solde
            FROM personne
            WHERE idPers = p_idPers;
        
            SELECT tarif INTO v_tarif
            FROM spectacle
            WHERE idSpect = p_idSpect;
            
            v_totalTarif := p_nbResa * v_tarif;
        
            IF v_solde < v_totalTarif THEN
                RAISE_APPLICATION_ERROR(-20002, 'Solde insuffisant');
            END IF;
        
            UPDATE personne
            SET solde = solde - v_totalTarif
            WHERE idPers = p_idPers;
        
            INSERT INTO reservation (idPers, idSpect, nbPlacesResa, dateResa)
            VALUES (p_idPers, p_idSpect, p_nbResa, SYSDATE);
        
            UPDATE spectacle
            SET nbPlacesLibres = nbPlacesLibres - p_nbResa
            WHERE idSpect = p_idSpect;
        
            DBMS_OUTPUT.PUT_LINE('Solde restant pour la personne ' || p_idPers || ' : ' || (v_solde - v_totalTarif));
            DBMS_OUTPUT.PUT_LINE('Nombre de places rserves : ' || p_nbResa);
        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20003, 'Donnes non trouves pour cette personne ou ce spectacle');
    END majPers;

END gestionSpec;
/

-- b) Utilisation du package

EXEC gestionSpec.ajoutPers('Spectateur',500);
EXEC gestionSpec.suppPers(4);
EXEC gestionSpec.majPers(p_idPers => 1, p_idSpect => 1, p_nbResa =>2);
EXEC gestionSpec.majPers(p_idPers => 2, p_idSpect => 1, p_nbResa =>2);
EXEC gestionSpec.majPers(p_idPers => 3, p_idSpect => 1, p_nbResa =>2);
EXEC gestionSpec.majPers(p_idPers => 4, p_idSpect => 1, p_nbResa =>2);
EXEC gestionSpec.infoSpect(1);


