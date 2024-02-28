/* Verifier les contraintes de clefs etrangeres */

/* Nombre total d appartements vendus au 1er semestre 2020. */
SELECT COUNT(*)
FROM public."Bien" AS b
RIGHT JOIN public."Vente" AS v ON b."Id_bien" = v."Id_bien" 
WHERE b."Type_local" = 'Appartement' AND v."date" BETWEEN '2020-01-01' AND '2020-06-30';

/* Le nombre de ventes d appartement par region pour le 1er semestre 2020. */
/* Focus sur les ventes, necessite des ventes avec l'info region */
SELECT r."Region", COUNT(*) AS total_appartements
FROM public."Bien" AS b
RIGHT JOIN public."Vente" AS v ON b."Id_bien" = v."Id_bien" 
INNER JOIN public."Commune" AS c ON b."Id_lieu" = c."Id_lieu"
INNER JOIN public."Region" AS r ON c."Code_Region" = r."Code_Region"
WHERE b."Type_local" = 'Appartement' AND v."date" BETWEEN '2020-01-01' AND '2020-06-30'
GROUP BY r."Region"
ORDER BY total_appartements DESC;

/* Proportion des ventes d appartements par le nombre de pieces */
/* Inner join : On s'interesse pas aux appartements non vendus ou les ventes sans informations sur le nb de pieces */ 
SELECT b."Total_piece",
    CONCAT(ROUND(CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()AS NUMERIC),1), '%') AS proportion
FROM public."Bien" AS b
INNER JOIN public."Vente" AS v ON b."Id_bien" = v."Id_bien" 
WHERE b."Type_local" = 'Appartement'
GROUP BY b."Total_piece"
ORDER BY b."Total_piece" ASC;


/* Liste des 10 departements ou le prix du metre carre est le plus eleve.*/
/* Inner : Necessite absolument les trois informations */ 
SELECT c."Code_Departement" AS Departement, 
	ROUND(AVG(CAST(v."valeur" / b."Surface_carrez" AS NUMERIC)),2) AS prix_m²
FROM public."Bien" AS b
INNER JOIN public."Vente" AS v ON b."Id_bien" = v."Id_bien"
INNER JOIN public."Commune" AS c ON b."Id_lieu" = c."Id_lieu"
WHERE v."valeur" IS NOT NULL
GROUP BY Departement
ORDER BY prix_m² DESC
LIMIT 10;

/* Prix moyen du metre carre d une maison en ile-de-France. */
/* De meme */ 
SELECT r."Region",
ROUND(AVG(CAST(v."valeur" / b."Surface_carrez" AS NUMERIC)),2) AS Moyenne_Prix_m²
FROM public."Bien" AS b
INNER JOIN public."Vente" AS v ON b."Id_bien" = v."Id_bien" 
INNER JOIN public."Commune" AS c ON b."Id_lieu" = c."Id_lieu"
INNER JOIN public."Region" AS r ON c."Code_Region" = r."Code_Region"
WHERE b."Type_local" = 'Maison' AND r."Region" = 'Ile-de-France'
GROUP BY r."Region";

/* Liste des 10 appartements les plus chers avec la region et le nombre de metres carres.*/
/* Beaucoup de resultats abherants, necessiterait une verif humaine sur la saisie de ces ventes */ 
SELECT v."valeur", r."Region", b."Surface_carrez", b."Surface_local"
FROM public."Bien" AS b
INNER JOIN public."Vente" AS v ON b."Id_bien" = v."Id_bien" 
INNER JOIN public."Commune" AS c ON b."Id_lieu" = c."Id_lieu"
INNER JOIN public."Region" AS r ON c."Code_Region" = r."Code_Region"
WHERE b."Type_local" = 'Appartement' AND valeur IS NOT NULL
ORDER BY v."valeur" DESC
LIMIT 10;

/* Taux d evolution du nombre de ventes entre le premier et le second trimestre de 2020. */
WITH vente_1er_trimestre AS (
	SELECT COUNT (*) AS nb_vente_1er_trimestre
	FROM public."Vente" AS v
	WHERE v."date" BETWEEN '2020-01-01' AND '2020-03-31'),
	 vente_2eme_trimestre AS(SELECT COUNT (*) AS nb_vente_2eme_trimestre
	FROM public."Vente" AS v
	WHERE v."date" BETWEEN '2020-04-01' AND '2020-06-30')
	
SELECT 
	CAST(vente_1er_trimestre."nb_vente_1er_trimestre" AS NUMERIC) AS vente_1er_trimestre,
	CAST(vente_2eme_trimestre."nb_vente_2eme_trimestre" AS NUMERIC) AS vente_2eme_trimestre, 
	CONCAT(ROUND((CAST(vente_2eme_trimestre."nb_vente_2eme_trimestre" AS NUMERIC) 
	 - CAST(vente_1er_trimestre."nb_vente_1er_trimestre" AS NUMERIC)) 
	 / CAST(vente_1er_trimestre."nb_vente_1er_trimestre" AS NUMERIC) * 100,3), '%') AS evolution
	
FROM vente_1er_trimestre, vente_2eme_trimestre;

/* Le classement des regions par rapport au prix au metre carre des
appartement de plus de 4 pieces. */
/* Dans la region ile de France, le prix au m² est plus cher dans les maisons de +4 pieces
Que la moyenne pour les maisons en idf, j'aurai tendance à penser le contraire car marché moins sous tension */ 
SELECT r."Region", ROUND(AVG(CAST(v."valeur" / b."Surface_carrez" AS NUMERIC)),2) AS prix_m²
FROM public."Bien" AS b
INNER JOIN public."Vente" AS v ON b."Id_bien" = v."Id_bien" 
INNER JOIN public."Commune" AS c ON b."Id_lieu" = c."Id_lieu"
INNER JOIN public."Region" AS r ON c."Code_Region" = r."Code_Region"
WHERE b."Total_piece" >= 4
GROUP BY r."Region"
ORDER BY prix_m² DESC;

/* Liste des communes ayant eu au moins 50 ventes au 1er trimestre */ 
Select c."Commune", 
	   COUNT(v."Id_vente") AS nb_vente
FROM public."Bien" AS b
INNER JOIN public."Vente" AS v ON b."Id_bien" = v."Id_bien" 
INNER JOIN public."Commune" AS c ON b."Id_lieu" = c."Id_lieu"
WHERE (v."date" BETWEEN '2020-01-01' AND '2020-06-30') AND (c."Commune" IS NOT NULL)
GROUP BY c."Commune"
HAVING COUNT(v."Id_vente") >= 50
ORDER BY nb_vente DESC;

/*  Difference en pourcentage du prix au metre carre entre un
appartement de 2 pieces et un appartement de 3 pieces. */
/* Logique, le prix diminue car moins de demande pour des logements plus cher dans l'absolu */
WITH 
	n2piece AS (
	 SELECT ROUND(AVG(CAST(v."valeur" / b."Surface_carrez" AS NUMERIC)),2) AS prix_2p
	 FROM public."Bien" AS b
	 INNER JOIN public."Vente" AS v ON b."Id_bien" = v."Id_bien"
	 WHERE b."Total_piece" = 2 AND b."Type_local" = 'Appartement'),
	n3piece AS (
	 SELECT ROUND(AVG(CAST(v."valeur" / b."Surface_carrez" AS NUMERIC)),2) AS prix_3p
	 FROM public."Bien" AS b
	 INNER JOIN public."Vente" AS v ON b."Id_bien" = v."Id_bien"
	 WHERE b."Total_piece" = 3 AND b."Type_local" = 'Appartement') 
		
SELECT 	
	ROUND(n2piece."prix_2p",2) AS prix2p,
	ROUND(n3piece."prix_3p",2) AS prix3p,
	CONCAT(ROUND(((n3piece."prix_3p" - n2piece."prix_2p") / n3piece."prix_3p")*100,2), '%') AS difference
FROM n2piece, n3piece; 

/* Les moyennes de valeurs foncières pour le top 3 des communes des départements 6, 13, 33, 59 et 69 */
/* Necessite une fenetre with pour inclure classement dans le WHERE */ 
WITH Classement_commune AS (
    SELECT 
        c."Commune", 
        c."Code_Departement",
        ROUND(AVG(v."valeur"), 2) AS Moyenne_valeur,
        RANK() OVER (PARTITION BY c."Code_Departement" ORDER BY AVG(v."valeur") DESC) AS Classement
    FROM public."Bien" AS b
    INNER JOIN public."Vente" AS v ON b."Id_bien" = v."Id_bien" 
    INNER JOIN public."Commune" AS c ON b."Id_lieu" = c."Id_lieu"
    WHERE c."Code_Departement" IN ('06', '13', '33', '59', '69')
    GROUP BY c."Commune", c."Code_Departement"
)
SELECT "Commune", "Code_Departement", Moyenne_valeur
FROM Classement_commune
WHERE Classement <= 3
ORDER BY "Code_Departement", Classement;

/* Les 20 communes avec le plus de transactions pour 1000 habitants
pour les communes qui depassent les 10 000 habitants. */
SELECT
    c."Commune",
    ROUND(CAST(COUNT(v."Id_vente") AS NUMERIC) * 1000 / CAST(c."Population" AS NUMERIC),2) AS transaction_pour_1000_habitants
FROM
    public."Bien" AS b
    INNER JOIN public."Vente" AS v ON b."Id_bien" = v."Id_bien"
    INNER JOIN public."Commune" AS c ON b."Id_lieu" = c."Id_lieu"
WHERE
    c."Population" > 10000
GROUP BY
    c."Commune", c."Population"
ORDER BY transaction_pour_1000_habitants DESC
LIMIT 20;

SELECT
	TO_CHAR(date, 'Mon') as mois,
	EXTRACT(MONTH FROM date) AS num,
	Count(*) as vente
FROM
    public."Vente"
GROUP BY 
	mois, num
ORDER BY num ASC


