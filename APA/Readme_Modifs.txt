Principales modifications entre Test_APA_v4 et Calc_APA_v5 :

- R�solution de bugs d'affichage des courbes (double clique n�cessaire pour mise � l'�chelle)
- Suppression des menus non utilis�s (ex.LFP)
- Modification de la fonction export c3d pour qu'elle fonctionne sur d'autres protocole que GBMOV
- On renomme TO en FO1, pour �viter confusion avec T0
- Nouvelle nomenclature des noms des variables (dans calcul_auto_APA_marker_v2.m et calculs_parametres_initiationPas_v5.m):
	- APAy -> APA_antpost
	- APAy_lateral -> APA_lateral
	- t_execution -> t_swing1
	- V_exec -> V_swing1	
	- t_step2 -> t_swing2
	

- Suppression de t_1step (car correspond � t_swing1 + APA)
