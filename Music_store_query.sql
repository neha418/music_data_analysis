--SET 1:
---Q1: Who is the senior most employee based on the job title?

SELECT first_name,last_name,title,levels
FROM employee
ORDER BY levels DESC
LIMIT 1;

---Q2: Which country has the most invoices?

SELECT billing_country, COUNT(invoice_id) AS total_invoices
FROM invoice
GROUP BY billing_country
ORDER BY total_invoices DESC;

---Q3: What are top 3 values of total invoice?

SELECT total 
FROM invoice
ORDER BY total DESC
LIMIT 3;

/*Q4: Which city has the best customers?We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals*/

SELECT billing_city, SUM(total) AS invoice_totals
FROM invoice
GROUP BY billing_city
ORDER BY invoice_totals DESC
LIMIT 1;

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

SELECT c.first_name,c.last_name, SUM(total) AS total_spending
FROM customer c
JOIN invoice
ON c.customer_id = invoice.customer_id
GROUP BY c.customer_id
ORDER BY total_spending DESC
LIMIT 1;

--------------------------------------------------------------------------------------

--SET 2:
/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

SELECT DISTINCT c.first_name,c.last_name,c.email
FROM customer c
JOIN invoice
ON c.customer_id = invoice.customer_id
JOIN invoice_line
ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
SELECT track_id
FROM track t
JOIN genre ON t.genre_id = genre.genre_id
WHERE genre.name = 'Rock')
ORDER BY c.email;

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

SELECT a.artist_id, a.name, COUNT(a.artist_id) AS total_track
FROM artist a
JOIN album
ON a.artist_id = album.artist_id
JOIN track
ON album.album_id = track.album_id
JOIN genre
ON track.genre_id = genre.genre_id
WHERE genre.name = 'Rock'
GROUP BY a.artist_id
ORDER BY total_track DESC
LIMIT 10;

/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

SELECT name,milliseconds
FROM track
WHERE milliseconds >(
SELECT AVG(milliseconds) AS avg_length
FROM track)
ORDER BY milliseconds DESC;

-------------------------------------------------------------------------------------------------------------------------

--SET 3:

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice
JOIN customer c ON c.customer_id = invoice.customer_id
JOIN invoice_line il ON il.invoice_id = invoice.invoice_id
JOIN track ON track.track_id = il.track_id
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN best_selling_artist bsa ON bsa.artist_id = artist.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */


WITH most_popular_genre AS(
	SELECT COUNT(il.quantity) AS purchases, customer.country,genre.name,genre.genre_id,
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(il.quantity)DESC) AS rownum
	FROM invoice_line il
	JOIN invoice ON invoice.invoice_id = il.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = il.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)

SELECT * FROM most_popular_genre
WHERE rownum <=1;

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

WITH star_customer AS(
	SELECT c.customer_id, c.first_name, c.last_name, i.billing_country, SUM(total) AS spent_total,
	ROW_NUMBER() OVER(PARTITION BY i.billing_country ORDER BY SUM(total) DESC) AS rowNum
	FROM customer c
	JOIN invoice i ON c.customer_id = i.customer_id
	GROUP BY 1,2,3,4
	ORDER BY 4 ASC, 5 DESC
)
SELECT *
FROM star_customer
WHERE rowNum <=1;