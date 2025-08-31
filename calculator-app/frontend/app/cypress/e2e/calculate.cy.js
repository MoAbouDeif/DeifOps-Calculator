describe('Calculator E2E', () => {
  it('performs a multiplication end-to-end', () => {
    cy.visit('/');

    cy.get('[data-testid="first-number-input"]').clear().type('3');
    cy.get('[data-testid="second-number-input"]').clear().type('5');
    cy.get('[data-testid="multiply-button"]').click();
    cy.get('[data-testid="calculate-button"]').click();

    // ✅ Wait until result appears
    cy.get('[data-testid="result-success"]').should('contain.text', 'Result: 15');

    // ✅ Ensure spinner is gone and button not busy at the end
    cy.get('[data-testid="spinner"]').should('not.exist');
    cy.get('[data-testid="calculate-button"]').should('have.attr', 'aria-busy', 'false');
  });

  it('handles divide-by-zero error from backend', () => {
    cy.visit('/');

    cy.get('[data-testid="first-number-input"]').clear().type('10');
    cy.get('[data-testid="second-number-input"]').clear().type('0');
    cy.get('[data-testid="divide-button"]').click();
    cy.get('[data-testid="calculate-button"]').click();

    cy.get('[data-testid="result-error"]').should('contain.text', 'Division by zero');
    cy.get('[data-testid="calculate-button"]').should('have.attr', 'aria-busy', 'false');
  });
});
