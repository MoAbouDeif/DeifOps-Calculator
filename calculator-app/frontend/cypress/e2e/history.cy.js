describe('History E2E', () => {
  it('loads and displays calculation history from backend', () => {
    cy.visit('/history');

    cy.get('[data-testid="history-list"]').should('exist');
    cy.get('[data-testid="history-item"]').should('have.length.greaterThan', 0);
    cy.get('[data-testid="history-item"]').first().should('contain.text', '=');
  });

  it('shows error UI when backend fails (simulated)', () => {
    cy.intercept('GET', '/api/history', {
      statusCode: 500,
      body: { error: 'Server error' },
    }).as('historyFail');

    cy.visit('/history');

    cy.wait('@historyFail');
    cy.get('[data-testid="history-error"]').should('contain.text', 'Server error');
  });
});
