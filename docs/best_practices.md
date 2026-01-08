# Engineering Best Practices

## Ruby
- Do not use `update_attributes`
- Always use `update!`
- Avoid callbacks for business logic
- Use service objects for complex flows
- Controllers must be thin; business logic must not live in controllers
- Do not rescue exceptions silently
- Use bang methods (`save!`, `update!`) for persistence

## Security
- Never trust params directly
- Always whitelist params
