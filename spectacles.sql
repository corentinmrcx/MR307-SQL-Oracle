DROP TABLE personne;
create table personne (idPers INTEGER ,
                         nom varchar2(30) not null,
                         solde INTEGER not null,
                         primary key (idPers))
                            ;
DROP TABLE spectacle;
create table Spectacle (  idSpect INTEGER ,
                          titre varchar2(30) not null,
                          nbPlaces INTEGER not null,
                          nbPlacesLibres INTEGER not null,
                          tarif NUMBER(8,2) not null,
                          primary key (idSpect))
                           ;

DROP TABLE Reservation; 
CREATE TABLE reservation (	idPers INTEGER
								CONSTRAINT fk_idPers REFERENCES PERSONNE(idPers),
							idSPect INTEGER
								CONSTRAINT fk_idSpect REFERENCES SPECTACLE(idSpect), 
							dateResa DATE,
							nbPlacesResa INTEGER NOT NULL,
							PRIMARY KEY (idPers, idSpect, dateResa)); 

-- Etat initial de la base: 2 clients, 2 spectacles

set autocommit 0;
delete from personne;
delete from Spectacle;
insert into personne values (1, 'Cesar', 2000);
insert into personne values (2, 'Augustin', 1000);
insert into Spectacle values (1, 'Ben hur', 250, 50, 50);
insert into Spectacle values (2, 'Tartuffe', 120, 30, 30);
commit;


-- Requêtes permettant d'examiner le comportement 
-- des transactions (isolation, blocage sur écritures 
-- concurrentes, commit et rollback)
set serveroutput ON

/* *************** procedures ****************** */
Create or replace procedure infoPers (p_idPers IN personne.idPers%TYPE)
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
END;
/


Create or replace procedure infoSpect (p_idSpect IN spectacle.idSpect%TYPE)
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
END;
/

CREATE OR REPLACE procedure SuppPers(p_idPers personne.idPers%TYPE)
IS
BEGIN
    DELETE FROM personne 
    WHERE idPers = p_idPers; 
    DBMS_OUTPUT.PUT_LINE ('personne '|| p_idPers || ' supprimée');

END;
/

