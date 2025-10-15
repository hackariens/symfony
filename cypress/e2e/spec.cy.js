describe('template spec', () => {
  it('passes', () => {
    cy.visit('https://symfony.traefik.me', {failOnStatusCode: false});
    cy.screenshot('first-page');
  })
})