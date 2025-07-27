select * from attendance
select * from department
select * from employee
select * from performance
select * from salary
select * from turnover

--Employee Retention Analysis
--Who are the top 5 highest serving employees?

SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    e.job_title,
    e.hire_date,
    EXTRACT(YEAR FROM AGE(NOW(), e.hire_date)) AS years_served
FROM 
    employee e
LEFT JOIN 
    turnover t ON e.employee_id = t.employee_id
WHERE 
    t.employee_id IS NULL   -- not in turnover, i.e., still employed
ORDER BY 
    e.hire_date ASC        -- earliest hire date = longest serving
LIMIT 5;

--What is the turnover rate for each department?

SELECT
    d.department_id,
    d.department_name,
    COUNT(DISTINCT t.employee_id) AS employees_left,
    COUNT(DISTINCT e.employee_id) AS total_employees,
    ROUND(
        (COUNT(DISTINCT t.employee_id)::decimal / NULLIF(COUNT(DISTINCT e.employee_id), 0)) * 100, 2
    ) AS turnover_rate_percent
FROM
    department d
LEFT JOIN employee e ON d.department_id = e.department_id
LEFT JOIN turnover t ON d.department_id = t.department_id
GROUP BY
    d.department_id, d.department_name
ORDER BY
    turnover_rate_percent DESC NULLS LAST;

--Which employees are at risk of leaving based on their performance?
--“At risk” = low recent performance score (let’s say ≤ 3)
--Only current employees (not in the turnover table).

WITH latest_performance AS (
    SELECT DISTINCT ON (employee_id)
        employee_id,
        performance_score,
        performance_date
    FROM performance
    ORDER BY employee_id, performance_date DESC
)
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    d.department_name,
    lp.performance_score,
    lp.performance_date
FROM employee e
LEFT JOIN turnover t ON e.employee_id = t.employee_id
LEFT JOIN department d ON e.department_id = d.department_id
LEFT JOIN latest_performance lp ON e.employee_id = lp.employee_id
WHERE
    t.employee_id IS NULL  -- still employed
    AND lp.performance_score <= 3  -- risk factor: low performance
ORDER BY
    lp.performance_score ASC, lp.performance_date DESC;

--What are the main reasons employees are leaving the company?

SELECT
    reason_for_leaving,
    COUNT(*) AS number_of_employees
FROM
    turnover
GROUP BY
    reason_for_leaving
ORDER BY
    number_of_employees DESC;

--Performance Analysis
--How many employees has left the company?

SELECT COUNT(DISTINCT employee_id) AS employees_left
FROM turnover;

--How many employees have a performance score of 5.0 / below 3.5?

WITH latest_performance AS (
    SELECT DISTINCT ON (employee_id)
        employee_id,
        performance_score
    FROM performance
    ORDER BY employee_id, performance_date DESC
)
SELECT
    SUM(CASE WHEN performance_score = 5.0 THEN 1 ELSE 0 END) AS score_5_count,
    SUM(CASE WHEN performance_score < 3.5 THEN 1 ELSE 0 END) AS below_3_5_count
FROM latest_performance;

--Which department has the most employees with a performance of 5.0 / below 3.5?

WITH latest_performance AS (
    SELECT DISTINCT ON (employee_id)
        employee_id,
        performance_score,
        department_id
    FROM performance
    ORDER BY employee_id, performance_date DESC
)
SELECT
    d.department_name,
    SUM(CASE WHEN lp.performance_score = 5.0 THEN 1 ELSE 0 END) AS score_5_count,
    SUM(CASE WHEN lp.performance_score < 3.5 THEN 1 ELSE 0 END) AS below_3_5_count
FROM latest_performance lp
JOIN department d ON lp.department_id = d.department_id
GROUP BY d.department_name
ORDER BY score_5_count DESC, below_3_5_count DESC;

--What is the average performance score by department?

WITH latest_performance AS (
    SELECT DISTINCT ON (employee_id)
        employee_id,
        performance_score,
        department_id
    FROM performance
    ORDER BY employee_id, performance_date DESC
)
SELECT
    d.department_name,
    ROUND(AVG(lp.performance_score), 2) AS avg_performance_score
FROM latest_performance lp
JOIN department d ON lp.department_id = d.department_id
GROUP BY d.department_name
ORDER BY avg_performance_score DESC;


--Salary Analysis
--What is the total salary expense for the company?

WITH latest_salary AS (
    SELECT DISTINCT ON (employee_id)
        employee_id,
        salary_amount
    FROM salary
    ORDER BY employee_id, salary_date DESC
)
SELECT
    SUM(salary_amount) AS total_salary_expense
FROM latest_salary;

--What is the average salary by job title?

WITH latest_salary AS (
    SELECT DISTINCT ON (employee_id)
        employee_id,
        salary_amount
    FROM salary
    ORDER BY employee_id, salary_date DESC
)
SELECT
    e.job_title,
    ROUND(AVG(ls.salary_amount), 2) AS avg_salary
FROM latest_salary ls
JOIN employee e ON ls.employee_id = e.employee_id
GROUP BY e.job_title
ORDER BY avg_salary DESC;

--How many employees earn above 80,000?

WITH latest_salary AS (
    SELECT DISTINCT ON (employee_id)
        employee_id,
        salary_amount
    FROM salary
    ORDER BY employee_id, salary_date DESC
)
SELECT
    COUNT(*) AS employees_above_80k
FROM latest_salary
WHERE salary_amount > 80000;

--How does performance correlate with salary across departments?

WITH latest_salary AS (
    SELECT DISTINCT ON (employee_id)
        employee_id,
        salary_amount,
        depaartment_id  -- typo from your table, keep as is!
    FROM salary
    ORDER BY employee_id, salary_date DESC
),
latest_performance AS (
    SELECT DISTINCT ON (employee_id)
        employee_id,
        performance_score
    FROM performance
    ORDER BY employee_id, performance_date DESC
)
SELECT
    d.department_name,
    ls.salary_amount,
    lp.performance_score
FROM latest_salary ls
JOIN latest_performance lp ON ls.employee_id = lp.employee_id
JOIN department d ON ls.depaartment_id = d.department_id;

--After the live class presentation. Q4 (Salary Analysis)
--Assuming I join salary, performance, and department tables using the most recent salary 
--and performance for each employee:

WITH latest_salary AS (
    SELECT DISTINCT ON (employee_id)
        employee_id,
        salary_amount,
        depaartment_id  -- (spelling as per in the table!)
    FROM salary
    ORDER BY employee_id, salary_date DESC
),
latest_performance AS (
    SELECT DISTINCT ON (employee_id)
        employee_id,
        performance_score,
        department_id
    FROM performance
    ORDER BY employee_id, performance_date DESC
)
SELECT
    d.department_name,
    ROUND(AVG(ls.salary_amount), 2) AS avg_salary,
    ROUND(AVG(lp.performance_score), 2) AS avg_performance
FROM latest_salary ls
JOIN latest_performance lp ON ls.employee_id = lp.employee_id
JOIN department d ON ls.depaartment_id = d.department_id
GROUP BY d.department_name
ORDER BY avg_salary DESC;  -- Or use avg_performance DESC for performance ranking

-- For ranking

WITH latest_salary AS (
    SELECT DISTINCT ON (employee_id)
        employee_id,
        salary_amount,
        depaartment_id -- typo as per your table
    FROM salary
    ORDER BY employee_id, salary_date DESC
),
latest_performance AS (
    SELECT DISTINCT ON (employee_id)
        employee_id,
        performance_score,
        department_id
    FROM performance
    ORDER BY employee_id, performance_date DESC
),
dept_stats AS (
    SELECT
        d.department_name,
        ROUND(AVG(ls.salary_amount), 2) AS avg_salary,
        ROUND(AVG(lp.performance_score), 2) AS avg_performance
    FROM latest_salary ls
    JOIN latest_performance lp ON ls.employee_id = lp.employee_id
    JOIN department d ON ls.depaartment_id = d.department_id
    GROUP BY d.department_name
)
SELECT
    department_name,
    avg_salary,
    avg_performance,
    RANK() OVER (ORDER BY avg_salary DESC) AS salary_rank,
    RANK() OVER (ORDER BY avg_performance DESC) AS performance_rank
FROM dept_stats;














