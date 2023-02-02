describe('template spec', () => {
  it('passes', () => {
    cy.visit('https://symfony.traefik.me');
    cy.screenshot('first-page');
  })
})